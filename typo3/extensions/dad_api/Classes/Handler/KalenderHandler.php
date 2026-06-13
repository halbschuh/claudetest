<?php
declare(strict_types=1);

namespace DadApi\Handler;

use DadApi\Middleware\ApiMiddleware;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Database\ConnectionPool;

/**
 * Exposes calendar events. Assumes EXT:cal or EXT:news is used for events in TYPO3.
 * Adapt the table name (tx_news_domain_model_news) to match your TYPO3 setup.
 */
final class KalenderHandler
{
    public function __construct(
        private readonly ApiMiddleware $apiMiddleware,
        private readonly ConnectionPool $connectionPool,
    ) {}

    public function list(ServerRequestInterface $request): ResponseInterface
    {
        $params = $request->getQueryParams();
        $year = (int)($params['year'] ?? date('Y'));
        $month = (int)($params['month'] ?? date('n'));

        $from = mktime(0, 0, 0, $month, 1, $year);
        $to = mktime(23, 59, 59, $month + 1, 0, $year);

        $qb = $this->connectionPool->getQueryBuilderForTable('tx_news_domain_model_news');
        $rows = $qb
            ->select('uid', 'title', 'datetime', 'bodytext', 'tags')
            ->from('tx_news_domain_model_news')
            ->where(
                $qb->expr()->gte('datetime', $qb->createNamedParameter($from, \PDO::PARAM_INT)),
                $qb->expr()->lte('datetime', $qb->createNamedParameter($to, \PDO::PARAM_INT)),
                $qb->expr()->eq('hidden', 0),
                $qb->expr()->eq('deleted', 0)
            )
            ->orderBy('datetime', 'ASC')
            ->executeQuery()
            ->fetchAllAssociative();

        $data = array_map(fn($row) => $this->serialize($row), $rows);
        return $this->apiMiddleware->json($data);
    }

    public function detail(ServerRequestInterface $request, int $id): ResponseInterface
    {
        $qb = $this->connectionPool->getQueryBuilderForTable('tx_news_domain_model_news');
        $row = $qb
            ->select('uid', 'title', 'datetime', 'bodytext', 'tags')
            ->from('tx_news_domain_model_news')
            ->where(
                $qb->expr()->eq('uid', $qb->createNamedParameter($id, \PDO::PARAM_INT)),
                $qb->expr()->eq('hidden', 0),
                $qb->expr()->eq('deleted', 0)
            )
            ->executeQuery()
            ->fetchAssociative();

        if (!$row) {
            return $this->apiMiddleware->json(['error' => 'Ereignis nicht gefunden'], 404);
        }

        return $this->apiMiddleware->json($this->serialize($row));
    }

    private function serialize(array $row): array
    {
        return [
            'id' => (int)$row['uid'],
            'title' => $row['title'],
            'historical_date' => date('c', (int)$row['datetime']),
            'description' => $row['bodytext'] ?: '',
            'ort_id' => null,
            'tags' => $row['tags'] ? explode(',', $row['tags']) : [],
            'image_url' => null,
        ];
    }
}
