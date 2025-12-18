# 1. Imagem Base
FROM php:8.2-apache

# 2. Instalar dependências de sistema
# Adicionei 'libicu-dev' que é obrigatório para a extensão intl
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-configure intl \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd opcache zip intl

# 3. Configurar Apache
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf
RUN a2enmod rewrite

# 4. Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. Configurar diretório
WORKDIR /var/www/html

# 6. Copiar arquivos
COPY . /var/www/html

# 7. Correção de segurança do Git
RUN git config --global --add safe.directory /var/www/html

# 8. Instalar dependências
RUN composer install --no-dev --optimize-autoloader --no-interaction

# 9. Permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# 10. Start
EXPOSE 80
CMD ["apache2-foreground"]
