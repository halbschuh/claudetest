<?php
declare(strict_types=1);

namespace DadApi\Handler;

use DadApi\Domain\Repository\OrtRepository;
use DadApi\Middleware\ApiMiddleware;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Resource\ResourceFactory;

final class OrteHandler
{
    public function __construct(
        private readonly OrtRepository $ortRepository,
        private readonly ApiMiddleware $apiMiddleware,
        private readonly ResourceFactory $resourceFactory,
    ) {}

    public function list(ServerRequestInterface $request): ResponseInterface
    {
        $rows = $this->ortRepository->findAll();
        $data = array_map(fn($row) => $this->serialize($row), $rows);
        return $this->apiMiddleware->json($data);
    }

    public function detail(ServerRequestInterface $request, int $id): ResponseInterface
    {
        $row = $this->ortRepository->findByUid($id);
        if ($row === null) {
            return $this->apiMiddleware->json(['error' => 'Ort not found'], 404);
        }
        return $this->apiMiddleware->json($this->serialize($row));
    }

    private function serialize(array $row): array
    {
        $thumbnailUrl = null;
        if ($row['thumbnail'] > 0) {
            try {
                $file = $this->resourceFactory->getFileObject($row['thumbnail']);
                $thumbnailUrl = $file->getPublicUrl();
            } catch (\Exception) {}
        }

        return [
            'id' => (int)$row['uid'],
            'name' => $row['name'],
            'description' => $row['description'] ?: null,
            'coordinate' => [
                'lat' => (float)$row['latitude'],
                'lng' => (float)$row['longitude'],
            ],
            'historical_period' => $row['historical_period'] ?: null,
            'thumbnail_url' => $thumbnailUrl,
            'lexikon_slugs' => $row['lexikon_slugs'] ? explode(',', $row['lexikon_slugs']) : [],
        ];
    }
}
