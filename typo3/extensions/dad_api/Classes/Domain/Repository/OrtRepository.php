<?php
declare(strict_types=1);

namespace DadApi\Domain\Repository;

use TYPO3\CMS\Core\Database\ConnectionPool;

final class OrtRepository
{
    public function __construct(private readonly ConnectionPool $connectionPool) {}

    public function findAll(): array
    {
        $qb = $this->connectionPool->getQueryBuilderForTable('tx_dadapi_domain_model_ort');
        return $qb
            ->select('uid', 'name', 'description', 'latitude', 'longitude', 'historical_period', 'thumbnail', 'lexikon_slugs')
            ->from('tx_dadapi_domain_model_ort')
            ->where($qb->expr()->eq('hidden', 0), $qb->expr()->eq('deleted', 0))
            ->orderBy('name', 'ASC')
            ->executeQuery()
            ->fetchAllAssociative();
    }

    public function findByUid(int $uid): ?array
    {
        $qb = $this->connectionPool->getQueryBuilderForTable('tx_dadapi_domain_model_ort');
        $row = $qb
            ->select('uid', 'name', 'description', 'latitude', 'longitude', 'historical_period', 'thumbnail', 'lexikon_slugs')
            ->from('tx_dadapi_domain_model_ort')
            ->where(
                $qb->expr()->eq('uid', $qb->createNamedParameter($uid, \PDO::PARAM_INT)),
                $qb->expr()->eq('hidden', 0),
                $qb->expr()->eq('deleted', 0)
            )
            ->executeQuery()
            ->fetchAssociative();
        return $row ?: null;
    }
}
