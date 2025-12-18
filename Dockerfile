# 1. Imagem Base (PHP 8.2 com Apache)
FROM php:8.2-apache

# 2. Instalar dependências essenciais e Opcache (Performance)
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd opcache

# 3. Configurar Apache para ler a pasta /public (Padrão Laravel/Moderno)
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# 4. Habilitar Mod Rewrite (Para URLs amigáveis funcionarem)
RUN a2enmod rewrite

# 5. Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. Configurar diretório de trabalho
WORKDIR /var/www/html

# 7. Copiar arquivos do projeto
COPY . /var/www/html

# 8. Instalar dependências (Otimizado)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# 9. Ajustar Permissões (Evita Erro 500/Permission Denied)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# 10. Expor porta 80 e Iniciar
EXPOSE 80
CMD ["apache2-foreground"]
