# 1. Usar PHP 8.2 com Apache
FROM php:8.2-apache

# 2. Instalar dependências do sistema e Node.js
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libicu-dev \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# 3. Configurar Git para confiar na pasta (Resolve o erro "dubious ownership")
RUN git config --global --add safe.directory /var/www/html

# 4. INSTALAR O COMPOSER
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. Instalar extensões PHP (Adicionada a extensão ZIP que faltava)
RUN docker-php-ext-configure intl \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip

# 6. Configurar Apache para ler a pasta PUBLIC
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf
RUN a2enmod rewrite

# 7. Copiar arquivos
WORKDIR /var/www/html
COPY . .

# 8. Rodar instalações
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs
RUN npm install && npm run build

# 9. Permissões Finais
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
