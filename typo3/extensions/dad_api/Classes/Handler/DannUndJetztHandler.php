<?php
declare(strict_types=1);

namespace DadApi\Handler;

use DadApi\Middleware\ApiMiddleware;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Database\ConnectionPool;
use TYPO3\CMS\Core\Resource\ResourceFactory;

final class DannUndJetztHandler
{
    public function __construct(
        private readonly ApiMiddleware $apiMiddleware,
        private readonly ConnectionPool $connectionPool,
        private readonly ResourceFactory $resourceFactory,
    ) {}

    public function list(ServerRequestInterface $request): ResponseInterface
    {
        $qb = $this->connectionPool->getQueryBuilderForTable('tx_dadapi_domain_model_dannundjetzt');
        $rows = $qb
            ->select('uid', 'ort_uid', 'historical_image', 'modern_image', 'caption', 'historical_year', 'modern_year')
            ->from('tx_dadapi_domain_model_dannundjetzt')
            ->where($qb->expr()->eq('hidden', 0), $qb->expr()->eq('deleted', 0))
            ->executeQuery()
            ->fetchAllAssociative();

        $data = array_map(fn($row) => $this->serialize($row), $rows);
        return $this->apiMiddleware->json($data);
    }

    private function serialize(array $row): array
    {
        return [
            'id' => (int)$row['uid'],
            'ort_id' => (int)$row['ort_uid'],
            'historical_image_url' => $this->fileUrl((int)$row['historical_image']),
            'modern_image_url' => $this->fileUrl((int)$row['modern_image']),
            'caption' => $row['caption'] ?: '',
            'historical_year' => $row['historical_year'] ? (int)$row['historical_year'] : null,
            'modern_year' => $row['modern_year'] ? (int)$row['modern_year'] : null,
        ];
    }

    private function fileUrl(int $fileUid): ?string
    {
        if ($fileUid <= 0) return null;
        try {
            return $this->resourceFactory->getFileObject($fileUid)->getPublicUrl();
        } catch (\Exception) {
            return null;
        }
    }
}
