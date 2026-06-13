<?php
declare(strict_types=1);

namespace DadApi\Handler;

use DadApi\Middleware\ApiMiddleware;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Database\ConnectionPool;
use TYPO3\CMS\Core\Resource\ResourceFactory;

/**
 * Proxies Lexikon content from TYPO3 pages/content elements via EXT:headless.
 * Assumes Lexikon entries are stored as TYPO3 pages with a specific page type (doktype).
 */
final class LexikonHandler
{
    // Page doktype used for Lexikon entries — configure in TYPO3 backend constants
    private const LEXIKON_DOKTYPE = 180;

    public function __construct(
        private readonly ApiMiddleware $apiMiddleware,
        private readonly ConnectionPool $connectionPool,
        private readonly ResourceFactory $resourceFactory,
    ) {}

    public function list(ServerRequestInterface $request): ResponseInterface
    {
        $qb = $this->connectionPool->getQueryBuilderForTable('pages');
        $rows = $qb
            ->select('uid', 'slug', 'title', 'description', 'media')
            ->from('pages')
            ->where(
                $qb->expr()->eq('doktype', self::LEXIKON_DOKTYPE),
                $qb->expr()->eq('hidden', 0),
                $qb->expr()->eq('deleted', 0)
            )
            ->orderBy('title', 'ASC')
            ->executeQuery()
            ->fetchAllAssociative();

        $data = array_map(fn($row) => [
            'id' => (int)$row['uid'],
            'slug' => ltrim($row['slug'], '/'),
            'title' => $row['title'],
            'teaser' => $row['description'] ?: '',
            'thumbnail_url' => $this->resolveFirstImage($row['uid']),
        ], $rows);

        return $this->apiMiddleware->json($data);
    }

    public function detail(ServerRequestInterface $request, string $slug): ResponseInterface
    {
        $qb = $this->connectionPool->getQueryBuilderForTable('pages');
        $page = $qb
            ->select('uid', 'slug', 'title', 'description')
            ->from('pages')
            ->where(
                $qb->expr()->like('slug', $qb->createNamedParameter('%/' . $slug)),
                $qb->expr()->eq('doktype', self::LEXIKON_DOKTYPE),
                $qb->expr()->eq('hidden', 0),
                $qb->expr()->eq('deleted', 0)
            )
            ->setMaxResults(1)
            ->executeQuery()
            ->fetchAssociative();

        if (!$page) {
            return $this->apiMiddleware->json(['error' => 'Eintrag nicht gefunden'], 404);
        }

        $bodyHTML = $this->assembleBodyHTML((int)$page['uid']);
        $imageURLs = $this->resolveImages((int)$page['uid']);

        return $this->apiMiddleware->json([
            'id' => (int)$page['uid'],
            'slug' => ltrim($page['slug'], '/'),
            'title' => $page['title'],
            'teaser' => $page['description'] ?: '',
            'body_html' => $bodyHTML,
            'image_urls' => $imageURLs,
            'linked_ort_i_ds' => [],
            'updated_at' => date('c'),
        ]);
    }

    private function assembleBodyHTML(int $pageUid): string
    {
        $qb = $this->connectionPool->getQueryBuilderForTable('tt_content');
        $elements = $qb
            ->select('bodytext', 'CType')
            ->from('tt_content')
            ->where(
                $qb->expr()->eq('pid', $qb->createNamedParameter($pageUid, \PDO::PARAM_INT)),
                $qb->expr()->eq('hidden', 0),
                $qb->expr()->eq('deleted', 0)
            )
            ->orderBy('sorting', 'ASC')
            ->executeQuery()
            ->fetchAllAssociative();

        return implode('', array_column($elements, 'bodytext'));
    }

    private function resolveFirstImage(int $pageUid): ?string
    {
        $urls = $this->resolveImages($pageUid, 1);
        return $urls[0] ?? null;
    }

    private function resolveImages(int $pageUid, int $limit = 20): array
    {
        $qb = $this->connectionPool->getQueryBuilderForTable('sys_file_reference');
        $refs = $qb
            ->select('uid_local')
            ->from('sys_file_reference')
            ->where(
                $qb->expr()->eq('uid_foreign', $qb->createNamedParameter($pageUid, \PDO::PARAM_INT)),
                $qb->expr()->eq('tablenames', $qb->createNamedParameter('pages')),
                $qb->expr()->eq('deleted', 0)
            )
            ->setMaxResults($limit)
            ->executeQuery()
            ->fetchAllAssociative();

        $urls = [];
        foreach ($refs as $ref) {
            try {
                $file = $this->resourceFactory->getFileObject((int)$ref['uid_local']);
                $urls[] = $file->getPublicUrl();
            } catch (\Exception) {}
        }
        return $urls;
    }
}
