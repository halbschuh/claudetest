<?php
declare(strict_types=1);

namespace DadApi\Handler;

use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Database\ConnectionPool;
use TYPO3\CMS\Core\Resource\ResourceFactory;
use TYPO3\CMS\Core\Utility\GeneralUtility;

final class SpaziergangHandler
{
    public function __construct(
        private readonly ResponseFactoryInterface $responseFactory,
        private readonly ResourceFactory $resourceFactory,
    ) {}

    public function list(ServerRequestInterface $request): ResponseInterface
    {
        $qb = GeneralUtility::makeInstance(ConnectionPool::class)
            ->getQueryBuilderForTable('tx_dadapi_domain_model_spaziergang');

        $rows = $qb->select('uid', 'title', 'description', 'duration_minutes', 'distance_meters', 'cover_image', 'tags')
            ->from('tx_dadapi_domain_model_spaziergang')
            ->where($qb->expr()->eq('hidden', 0), $qb->expr()->eq('deleted', 0))
            ->orderBy('title')
            ->executeQuery()
            ->fetchAllAssociative();

        $data = array_map(fn($row) => $this->serializeListItem($row), $rows);

        return $this->json($data);
    }

    public function detail(ServerRequestInterface $request, int $uid): ResponseInterface
    {
        $qb = GeneralUtility::makeInstance(ConnectionPool::class)
            ->getQueryBuilderForTable('tx_dadapi_domain_model_spaziergang');

        $row = $qb->select('*')
            ->from('tx_dadapi_domain_model_spaziergang')
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

        $waypoints = $this->fetchWaypoints($uid);

        return $this->json($this->serializeDetail($row, $waypoints));
    }

    private function fetchWaypoints(int $spaziergangUid): array
    {
        $qb = GeneralUtility::makeInstance(ConnectionPool::class)
            ->getQueryBuilderForTable('tx_dadapi_domain_model_wegpunkt');

        $rows = $qb->select('*')
            ->from('tx_dadapi_domain_model_wegpunkt')
            ->where(
                $qb->expr()->eq('spaziergang_uid', $spaziergangUid),
                $qb->expr()->eq('hidden', 0),
                $qb->expr()->eq('deleted', 0)
            )
            ->orderBy('sort_order')
            ->executeQuery()
            ->fetchAllAssociative();

        return array_map(fn($row) => $this->serializeWaypoint($row), $rows);
    }

    private function serializeListItem(array $row): array
    {
        return [
            'id' => (int)$row['uid'],
            'title' => $row['title'],
            'description' => $row['description'] ?? '',
            'duration_minutes' => (int)$row['duration_minutes'],
            'distance_meters' => (int)$row['distance_meters'],
            'cover_image_url' => $this->resolveFileUrl((int)$row['cover_image']),
            'tags' => $row['tags'] ? array_filter(explode(',', $row['tags'])) : [],
        ];
    }

    private function serializeDetail(array $row, array $waypoints): array
    {
        return array_merge($this->serializeListItem($row), ['waypoints' => $waypoints]);
    }

    private function serializeWaypoint(array $row): array
    {
        return [
            'id' => (int)$row['uid'],
            'coordinate' => ['lat' => (float)$row['latitude'], 'lng' => (float)$row['longitude']],
            'title' => $row['title'],
            'body_text' => $row['body_text'] ?? '',
            'audio_url' => $this->resolveFileUrl((int)$row['audio_file']),
            'image_urls' => [],
            'sort_order' => (int)$row['sort_order'],
        ];
    }

    private function resolveFileUrl(int $fileUid): ?string
    {
        if ($fileUid === 0) {
            return null;
        }
        try {
            $file = $this->resourceFactory->getFileObject($fileUid);
            return $file->getPublicUrl();
        } catch (\Throwable) {
            return null;
        }
    }

    private function json(mixed $data, int $status = 200): ResponseInterface
    {
        $response = $this->responseFactory->createResponse($status);
        $response->getBody()->write(json_encode(['data' => $data], JSON_UNESCAPED_UNICODE));
        return $response->withHeader('Content-Type', 'application/json; charset=utf-8')
                        ->withHeader('Access-Control-Allow-Origin', '*');
    }
}
