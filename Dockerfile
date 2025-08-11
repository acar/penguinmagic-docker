FROM php:8.3-apache

# Debug: Check what mirrors are configured in base image
RUN echo "=== Base image APT config ===" \
    && cat /etc/apt/sources.list.d/debian.sources || cat /etc/apt/sources.list || echo "No sources found" \
    && echo "=== APT config ===" \
    && ls -la /etc/apt/apt.conf.d/ \
    && echo "========================"

# Install required PHP extensions
RUN docker-php-ext-install pdo pdo_mysql

# Add APT config to handle broken proxies/caches
RUN echo 'Acquire::http::Pipeline-Depth 0;' > /etc/apt/apt.conf.d/99fix-broken-proxy \
    && echo 'Acquire::http::No-Cache true;' >> /etc/apt/apt.conf.d/99fix-broken-proxy \
    && echo 'Acquire::BrokenProxy true;' >> /etc/apt/apt.conf.d/99fix-broken-proxy

RUN apt-get clean && apt-get update && apt-get install -y \
    pkg-config \
    build-essential \
    unzip \
    curl \
    git \
    imagemagick \
    libmagickwand-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libzip-dev \
    && (pecl install imagick || true) \
    && (pecl install apcu || true) \
    && docker-php-ext-enable imagick \
    && docker-php-ext-enable apcu \
    && docker-php-ext-install pdo pdo_mysql zip gd sockets \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN curl -sS https://getcomposer.org/download/2.2.22/composer.phar -o /usr/local/bin/composer \
 && chmod +x /usr/local/bin/composer


# Enable Apache mod_rewrite (optional, for frameworks like Laravel or WordPress)
RUN a2enmod rewrite 
RUN a2enmod ssl

RUN mkdir -p /home/pmagic/www

WORKDIR /home/pmagic
COPY composer.lock composer.json ./

# Set the new DocumentRoot
RUN sed -i 's|/var/www/html|/home/pmagic/www|g' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's|/var/www|/home/pmagic|g' /etc/apache2/apache2.conf

# Ensure permissions are set correctly
RUN chown -R www-data:www-data /home/pmagic
#RUN composer install --no-dev --optimize-autoloader

EXPOSE 80
EXPOSE 443

