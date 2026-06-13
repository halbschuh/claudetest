<?php
return [
    'ctrl' => [
        'title' => 'Historischer Ort',
        'label' => 'name',
        'tstamp' => 'tstamp',
        'crdate' => 'crdate',
        'delete' => 'deleted',
        'enablecolumns' => ['disabled' => 'hidden'],
        'iconfile' => 'EXT:dad_api/Resources/Public/Icons/ort.svg',
        'searchFields' => 'name,description',
    ],
    'columns' => [
        'name' => [
            'label' => 'Name',
            'config' => ['type' => 'input', 'size' => 50, 'required' => true],
        ],
        'description' => [
            'label' => 'Beschreibung',
            'config' => ['type' => 'text', 'rows' => 5, 'enableRichtext' => true],
        ],
        'latitude' => [
            'label' => 'Breitengrad',
            'config' => ['type' => 'number', 'format' => 'decimal', 'required' => true],
        ],
        'longitude' => [
            'label' => 'Längengrad',
            'config' => ['type' => 'number', 'format' => 'decimal', 'required' => true],
        ],
        'historical_period' => [
            'label' => 'Historischer Zeitraum (z.B. 1890–1945)',
            'config' => ['type' => 'input', 'size' => 30],
        ],
        'thumbnail' => [
            'label' => 'Vorschaubild',
            'config' => [
                'type' => 'file',
                'maxitems' => 1,
                'allowed' => 'jpg,jpeg,png,webp',
            ],
        ],
        'lexikon_slugs' => [
            'label' => 'Verknüpfte Lexikon-Slugs (kommagetrennt)',
            'config' => ['type' => 'input', 'size' => 80],
        ],
    ],
    'types' => [
        '1' => ['showitem' => 'hidden, name, description, latitude, longitude, historical_period, thumbnail, lexikon_slugs'],
    ],
];
