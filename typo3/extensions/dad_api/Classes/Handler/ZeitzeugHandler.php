<?php
declare(strict_types=1);

namespace DadApi\Handler;

use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Database\ConnectionPool;
use TYPO3\CMS\Core\Resource\ResourceFactory;
use TYPO3\CMS\Core\Utility\GeneralUtility;

final class ZeitzeugHandler
{
    public function __construct(
        private readonly ResponseFactoryInterface $responseFactory,
        private readonly ResourceFactory $resourceFactory,
    ) {}

    public function list(ServerRequestInterface $request): ResponseInterface
    {
        $qb = GeneralUtility::makeInstance(ConnectionPool::class)
            ->getQueryBuilderForTable('tx_dadapi_domain_model_zeitzeug');

        $rows = $qb->select('uid', 'title', 'author_name', 'ort_uid', 'teaser', 'period', 'thumbnail', 'published_at')
            ->from('tx_dadapi_domain_model_zeitzeug')
            ->where($qb->expr()->eq('hidden', 0), $qb->expr()->eq('deleted', 0))
            ->orderBy('published_at', 'DESC')
            ->executeQuery()
            ->fetchAllAssociative();

        return $this->json(array_map(fn($row) => $this->serializeListItem($row), $rows));
    }

    public function detail(ServerRequestInterface $request, int $uid): ResponseInterface
    {
        $qb = GeneralUtility::makeInstance(ConnectionPool::class)
            ->getQueryBuilderForTable('tx_dadapi_domain_model_zeitzeug');

        $row = $qb->select('*')
            ->from('tx_dadapi_domain_model_zeitzeug')
            ->where(
                $qb->expr()->eq('uid', $uid),
                $qb->expr()->eq('hidden', 0),
                $qb->expr()->eq('deleted', 0)
            )
            ->executeQuery()
            ->fetchAssociative();

        if (!$row) {
            return $this->json(['error' => 'Not found'], 404);
        }

        return $this->json($this->serializeDetail($row));
    }

    private function serializeListItem(array $row): array
    {
        return [
            'id' => (int)$row['uid'],
            'title' => $row['title'],
            'author_name' => $row['author_name'] ?: null,
            'ort_id' => $row['ort_uid'] ? (int)$row['ort_uid'] : null,
            'teaser' => $row['teaser'] ?? '',
            'period' => $row['period'] ?: null,
            'thumbnail_url' => $this->resolveFileUrl((int)$row['thumbnail']),
            'published_at' => date('c', (int)$row['published_at']),
        ];
    }

    private function serializeDetail(array $row): array
    {
        return array_merge($this->serializeListItem($row), [
            'body_html' => $row['body_html'] ?? '',
            'image_urls' => $this->resolveReferenceUrls((int)$row['uid']),
        ]);
    }

    private function resolveFileUrl(int $fileUid): ?string
    {
        if ($fileUid === 0) {
            return null;
        }
        try {
            return $this->resourceFactory->getFileObject($fileUid)->getPublicUrl();
        } catch (\Throwable) {
            return null;
        }
    }

    private function resolveReferenceUrls(int $recordUid): array
    {
        $qb = GeneralUtility::makeInstance(ConnectionPool::class)
            ->getQueryBuilderForTable('sys_file_reference');

        $refs = $qb->select('uid_local')
            ->from('sys_file_reference')
            ->where(
                $qb->expr()->eq('tablenames', $qb->createNamedParameter('tx_dadapi_domain_model_zeitzeug')),
                $qb->expr()->eq('uid_foreign', $recordUid),
                $qb->expr()->eq('deleted', 0)
            )
            ->orderBy('sorting_foreign')
            ->executeQuery()
            ->fetchAllAssociative();

        $urls = [];
        foreach ($refs as $ref) {
            try {
                $urls[] = $this->resourceFactory->getFileObject((int)$ref['uid_local'])->getPublicUrl();
            } catch (\Throwable) {
            }
        }

        return $urls;
    }

    private function json(mixed $data, int $status = 200): ResponseInterface
    {
        $response = $this->responseFactory->createResponse($status);
        $response->getBody()->write(json_encode(['data' => $data], JSON_UNESCAPED_UNICODE));
        return $response->withHeader('Content-Type', 'application/json; charset=utf-8')
                        ->withHeader('Access-Control-Allow-Origin', '*');
    }
}
