<?php
$EM_CONF[$_EXTKEY] = [
    'title' => 'Das alte Dresden API',
    'description' => 'REST API for the Das alte Dresden iOS app. Exposes Lexikon, Kalender, Orte, and handles photo uploads.',
    'version' => '1.0.0',
    'state' => 'alpha',
    'author' => 'Das alte Dresden',
    'author_email' => 'ss@neonblue.de',
    'constraints' => [
        'depends' => [
            'typo3' => '12.0.0-13.99.99',
            'headless' => '4.0.0-4.99.99',
        ],
    ],
];
