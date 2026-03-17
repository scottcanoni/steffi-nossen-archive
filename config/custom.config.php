<?php

/**
 * Nextcloud custom configuration overrides.
 *
 * Place this file in the Nextcloud config directory. When using AIO,
 * mount it into the Nextcloud container at /var/www/html/config/custom.config.php
 * or apply these values via occ commands after first boot.
 *
 * See: https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html
 */

$CONFIG = [
    // Preview generation settings for the archive's photo/video heavy workload.
    'preview_max_x' => 2048,
    'preview_max_y' => 2048,
    'preview_max_filesize_image' => 256, // MB

    'enabledPreviewProviders' => [
        'OC\Preview\PNG',
        'OC\Preview\JPEG',
        'OC\Preview\GIF',
        'OC\Preview\BMP',
        'OC\Preview\XBitmap',
        'OC\Preview\MP3',
        'OC\Preview\TXT',
        'OC\Preview\MarkDown',
        'OC\Preview\OpenDocument',
        'OC\Preview\Krita',
        'OC\Preview\HEIC',
        'OC\Preview\Movie',
        'OC\Preview\MKV',
        'OC\Preview\MP4',
        'OC\Preview\AVI',
    ],

    // Default phone region (used for phone number validation).
    'default_phone_region' => 'US',

    // Logging: keep it reasonable, rotate automatically.
    'loglevel' => 2, // 0=debug, 1=info, 2=warn, 3=error, 4=fatal
    'log_rotate_size' => 104857600, // 100 MB

    // Disable skeleton files for new users (archive users don't need sample docs).
    'skeletondirectory' => '',
    'templatedirectory' => '',

    // Maintenance window for background jobs (2 AM - 5 AM server time).
    'maintenance_window_start' => 2,
];
