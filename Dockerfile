FROM php:8.2-cli

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends         git unzip curl wget ca-certificates         libicu-dev libjpeg-dev libpng-dev libwebp-dev         libzip-dev libyaml-dev libsodium-dev         build-essential pkg-config         default-mysql-client gettext-base         && rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-configure gd --with-jpeg --with-webp      && docker-php-ext-install -j$(nproc)         gd intl bcmath zip pdo_mysql opcache sodium

# pecl: yaml
RUN pecl install yaml      && docker-php-ext-enable yaml

# Composer
RUN php -r "copy('https://getcomposer.org/installer','/tmp/composer-setup.php');"      && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer      && rm /tmp/composer-setup.php

# Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -      && apt-get update && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

# Code
WORKDIR /opt
RUN git clone https://github.com/openvk/chandler.git
WORKDIR /opt/chandler
RUN composer install --no-dev --prefer-dist --no-interaction

# Extensions
WORKDIR /opt/chandler/extensions/available
RUN git clone https://github.com/openvk/openvk.git      && git clone https://github.com/openvk/commitcaptcha.git
RUN ln -s ../available/openvk ../enabled/openvk      && ln -s ../available/commitcaptcha ../enabled/commitcaptcha

# Build frontend
WORKDIR /opt/chandler/extensions/available/openvk/Web/static/js
RUN npm install && npm run build

# Configs
WORKDIR /opt/chandler
COPY config/chandler.yml /opt/chandler/chandler.yml
COPY config/openvk.yml.template /opt/chandler/extensions/available/openvk/openvk.yml.template

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
CMD ["/entrypoint.sh"]
