<?php
declare(strict_types=1);

namespace DadApi\Handler;

use DadApi\Middleware\ApiMiddleware;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Database\ConnectionPool;
use TYPO3\CMS\Core\Resource\ResourceFactory;
use TYPO3\CMS\Core\Resource\StorageRepository;

final class FotoHandler
{
    // FAL storage uid for user uploads — configure in TYPO3 backend
    private const UPLOAD_STORAGE_UID = 1;
    private const UPLOAD_FOLDER = 'user-uploads/fotos/';

    public function __construct(
        private readonly ApiMiddleware $apiMiddleware,
        private readonly ConnectionPool $connectionPool,
        private readonly ResourceFactory $resourceFactory,
        private readonly StorageRepository $storageRepository,
    ) {}

    public function upload(ServerRequestInterface $request): ResponseInterface
    {
        $uploadedFiles = $request->getUploadedFiles();
        if (empty($uploadedFiles['photo'])) {
            return $this->apiMiddleware->json(['error' => 'Kein Foto übermittelt'], 400);
        }

        $uploadedFile = $uploadedFiles['photo'];
        if ($uploadedFile->getError() !== UPLOAD_ERR_OK) {
            return $this->apiMiddleware->json(['error' => 'Upload-Fehler'], 500);
        }

        // Parse metadata from multipart body
        $metaBody = $request->getParsedBody()['metadata'] ?? '{}';
        $meta = json_decode(is_string($metaBody) ? $metaBody : '{}', true) ?? [];

        // Store via FAL so the file appears in TYPO3 backend
        $storage = $this->storageRepository->findByUid(self::UPLOAD_STORAGE_UID);
        $folder = $storage->getFolder(self::UPLOAD_FOLDER);

        $filename = sprintf('%s_%s.jpg', date('Ymd_His'), bin2hex(random_bytes(4)));
        $tempPath = $uploadedFile->getStream()->getMetadata('uri');
        $file = $storage->addFile($tempPath, $folder, $filename);

        // Persist submission record
        $conn = $this->connectionPool->getConnectionForTable('tx_dadapi_domain_model_userfoto');
        $conn->insert('tx_dadapi_domain_model_userfoto', [
            'pid' => (int)($GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['dad_api']['uploadPid'] ?? 1),
            'crdate' => time(),
            'tstamp' => time(),
            'uploader_name' => substr($meta['uploaderName'] ?? '', 0, 255),
            'location_description' => $meta['locationDescription'] ?? '',
            'latitude' => isset($meta['latitude']) ? (float)$meta['latitude'] : null,
            'longitude' => isset($meta['longitude']) ? (float)$meta['longitude'] : null,
            'ort_uid' => (int)($meta['ortID'] ?? 0),
            'image' => $file->getUid(),
            'status' => 'pending',
        ]);

        return $this->apiMiddleware->json(['status' => 'pending'], 201);
    }
}
