<?php
declare(strict_types=1);

namespace DadApi\Handler;

use DadApi\Middleware\ApiMiddleware;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use TYPO3\CMS\Core\Database\ConnectionPool;
use TYPO3\CMS\Core\Crypto\PasswordHashing\PasswordHashFactory;

/**
 * Handles authentication against TYPO3's fe_users table.
 * Issues a signed JWT; the secret is set via TYPO3_CONF_VARS['EXTENSIONS']['dad_api']['jwtSecret'].
 */
final class AuthHandler
{
    public function __construct(
        private readonly ApiMiddleware $apiMiddleware,
        private readonly ConnectionPool $connectionPool,
        private readonly PasswordHashFactory $passwordHashFactory,
    ) {}

    public function login(ServerRequestInterface $request): ResponseInterface
    {
        $body = json_decode((string)$request->getBody(), true) ?? [];
        $email = trim($body['email'] ?? '');
        $password = $body['password'] ?? '';

        if ($email === '' || $password === '') {
            return $this->apiMiddleware->json(['error' => 'E-Mail und Passwort erforderlich'], 400);
        }

        $user = $this->findUser($email);
        if ($user === null) {
            return $this->apiMiddleware->json(['error' => 'Ungültige Zugangsdaten'], 401);
        }

        $hashService = $this->passwordHashFactory->get($user['password'], 'FE');
        if (!$hashService->checkPassword($password, $user['password'])) {
            return $this->apiMiddleware->json(['error' => 'Ungültige Zugangsdaten'], 401);
        }

        $tokens = $this->issueTokens((int)$user['uid']);
        return $this->apiMiddleware->json($tokens);
    }

    public function register(ServerRequestInterface $request): ResponseInterface
    {
        $body = json_decode((string)$request->getBody(), true) ?? [];
        $email = trim($body['email'] ?? '');
        $password = $body['password'] ?? '';
        $name = trim($body['name'] ?? '');

        if ($email === '' || $password === '' || $name === '') {
            return $this->apiMiddleware->json(['error' => 'Alle Felder erforderlich'], 400);
        }

        if ($this->findUser($email) !== null) {
            return $this->apiMiddleware->json(['error' => 'E-Mail bereits registriert'], 409);
        }

        $hashService = $this->passwordHashFactory->getDefaultHashInstance('FE');
        $hashedPassword = $hashService->getHashedPassword($password);

        $conn = $this->connectionPool->getConnectionForTable('fe_users');
        $conn->insert('fe_users', [
            'pid' => (int)($GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['dad_api']['feUsersPid'] ?? 1),
            'username' => $email,
            'password' => $hashedPassword,
            'email' => $email,
            'name' => $name,
            'crdate' => time(),
            'tstamp' => time(),
        ]);

        $uid = (int)$conn->lastInsertId('fe_users');
        $tokens = $this->issueTokens($uid);
        return $this->apiMiddleware->json($tokens, 201);
    }

    public function refresh(ServerRequestInterface $request): ResponseInterface
    {
        $body = json_decode((string)$request->getBody(), true) ?? [];
        $refreshToken = $body['refresh_token'] ?? '';

        $payload = $this->verifyToken($refreshToken);
        if ($payload === null || ($payload['type'] ?? '') !== 'refresh') {
            return $this->apiMiddleware->json(['error' => 'Ungültiger Token'], 401);
        }

        $tokens = $this->issueTokens((int)$payload['uid']);
        return $this->apiMiddleware->json($tokens);
    }

    // MARK: - JWT helpers (HS256, no third-party library)

    private function issueTokens(int $uid): array
    {
        return [
            'access_token' => $this->createToken($uid, 'access', 3600),
            'refresh_token' => $this->createToken($uid, 'refresh', 2592000),
            'expires_in' => 3600,
        ];
    }

    private function createToken(int $uid, string $type, int $ttl): string
    {
        $header = $this->base64url(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $payload = $this->base64url(json_encode([
            'uid' => $uid,
            'type' => $type,
            'iat' => time(),
            'exp' => time() + $ttl,
        ]));
        $signature = $this->base64url(hash_hmac('sha256', "$header.$payload", $this->jwtSecret(), true));
        return "$header.$payload.$signature";
    }

    private function verifyToken(string $token): ?array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) return null;
        [$header, $payload, $signature] = $parts;
        $expected = $this->base64url(hash_hmac('sha256', "$header.$payload", $this->jwtSecret(), true));
        if (!hash_equals($expected, $signature)) return null;
        $data = json_decode(base64_decode(strtr($payload, '-_', '+/')), true);
        if (($data['exp'] ?? 0) < time()) return null;
        return $data;
    }

    private function base64url(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private function jwtSecret(): string
    {
        return $GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['dad_api']['jwtSecret']
            ?? throw new \RuntimeException('dad_api jwtSecret not configured in TYPO3_CONF_VARS');
    }

    private function findUser(string $email): ?array
    {
        $qb = $this->connectionPool->getQueryBuilderForTable('fe_users');
        $row = $qb
            ->select('uid', 'username', 'password', 'email', 'name')
            ->from('fe_users')
            ->where(
                $qb->expr()->eq('username', $qb->createNamedParameter($email)),
                $qb->expr()->eq('deleted', 0),
                $qb->expr()->eq('disable', 0)
            )
            ->setMaxResults(1)
            ->executeQuery()
            ->fetchAssociative();
        return $row ?: null;
    }
}
