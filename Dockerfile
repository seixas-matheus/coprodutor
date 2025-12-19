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
    libicu-dev \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# 3. INSTALAR O COMPOSER (Isso resolve o erro que deu antes)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Instalar extensões PHP
RUN docker-php-ext-configure intl \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl

# 5. Configurar Apache para ler a pasta PUBLIC
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf
RUN a2enmod rewrite

# 6. Copiar arquivos
WORKDIR /var/www/html
COPY . .

# 7. Rodar instalações
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs
RUN npm install && npm run build

# 8. Permissões Finais
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
