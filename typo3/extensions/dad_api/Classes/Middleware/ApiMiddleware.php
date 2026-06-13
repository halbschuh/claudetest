<?php
declare(strict_types=1);

namespace DadApi\Middleware;

use DadApi\Handler\LexikonHandler;
use DadApi\Handler\KalenderHandler;
use DadApi\Handler\OrteHandler;
use DadApi\Handler\DannUndJetztHandler;
use DadApi\Handler\SpaziergangHandler;
use DadApi\Handler\ZeitzeugHandler;
use DadApi\Handler\FotoHandler;
use DadApi\Handler\AuthHandler;
use Psr\Http\Message\ResponseFactoryInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;

/**
 * PSR-15 middleware that routes /api/v1/* requests to the appropriate handler.
 * Intercepts before TYPO3's page resolver so API calls never trigger CMS page rendering.
 */
final class ApiMiddleware implements MiddlewareInterface
{
    private const API_PREFIX = '/api/v1';

    public function __construct(
        private readonly ResponseFactoryInterface $responseFactory,
        private readonly LexikonHandler $lexikonHandler,
        private readonly KalenderHandler $kalenderHandler,
        private readonly OrteHandler $orteHandler,
        private readonly DannUndJetztHandler $dannUndJetztHandler,
        private readonly SpaziergangHandler $spaziergangHandler,
        private readonly ZeitzeugHandler $zeitzeugHandler,
        private readonly FotoHandler $fotoHandler,
        private readonly AuthHandler $authHandler,
    ) {}

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        $path = $request->getUri()->getPath();

        if (!str_starts_with($path, self::API_PREFIX)) {
            return $handler->handle($request);
        }

        $route = substr($path, strlen(self::API_PREFIX));
        $method = strtoupper($request->getMethod());

        return $this->route($request, $route, $method);
    }

    private function route(ServerRequestInterface $request, string $route, string $method): ResponseInterface
    {
        // /lexikon
        if ($route === '/lexikon' && $method === 'GET') {
            return $this->lexikonHandler->list($request);
        }
        if (preg_match('#^/lexikon/(?P<slug>[a-z0-9\-]+)$#', $route, $m) && $method === 'GET') {
            return $this->lexikonHandler->detail($request, $m['slug']);
        }

        // /kalender
        if ($route === '/kalender' && $method === 'GET') {
            return $this->kalenderHandler->list($request);
        }
        if (preg_match('#^/kalender/(?P<id>\d+)$#', $route, $m) && $method === 'GET') {
            return $this->kalenderHandler->detail($request, (int)$m['id']);
        }

        // /orte
        if ($route === '/orte' && $method === 'GET') {
            return $this->orteHandler->list($request);
        }
        if (preg_match('#^/orte/(?P<id>\d+)$#', $route, $m) && $method === 'GET') {
            return $this->orteHandler->detail($request, (int)$m['id']);
        }

        // /dann-und-jetzt
        if ($route === '/dann-und-jetzt' && $method === 'GET') {
            return $this->dannUndJetztHandler->list($request);
        }

        // /spaziergaenge
        if ($route === '/spaziergaenge' && $method === 'GET') {
            return $this->spaziergangHandler->list($request);
        }
        if (preg_match('#^/spaziergaenge/(?P<id>\d+)$#', $route, $m) && $method === 'GET') {
            return $this->spaziergangHandler->detail($request, (int)$m['id']);
        }

        // /zeitzeugen
        if ($route === '/zeitzeugen' && $method === 'GET') {
            return $this->zeitzeugHandler->list($request);
        }
        if (preg_match('#^/zeitzeugen/(?P<id>\d+)$#', $route, $m) && $method === 'GET') {
            return $this->zeitzeugHandler->detail($request, (int)$m['id']);
        }

        // /fotos
        if ($route === '/fotos' && $method === 'POST') {
            return $this->fotoHandler->upload($request);
        }

        // /auth
        if ($route === '/auth/login' && $method === 'POST') {
            return $this->authHandler->login($request);
        }
        if ($route === '/auth/register' && $method === 'POST') {
            return $this->authHandler->register($request);
        }
        if ($route === '/auth/refresh' && $method === 'POST') {
            return $this->authHandler->refresh($request);
        }

        return $this->json(['error' => 'Not found'], 404);
    }

    public function json(mixed $data, int $status = 200): ResponseInterface
    {
        $response = $this->responseFactory->createResponse($status);
        $response->getBody()->write(json_encode(['data' => $data], JSON_UNESCAPED_UNICODE));
        return $response->withHeader('Content-Type', 'application/json; charset=utf-8')
                        ->withHeader('Access-Control-Allow-Origin', '*');
    }
}
