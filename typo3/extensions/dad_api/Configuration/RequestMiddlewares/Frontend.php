<?php
return [
    'frontend' => [
        'dad-api/router' => [
            'target' => \DadApi\Middleware\ApiMiddleware::class,
            'before' => ['typo3/cms-frontend/page-resolver'],
            'after' => ['typo3/cms-core/normalized-params-attribute'],
        ],
    ],
];
