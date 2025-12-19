# 1. Base
FROM php:8.2-apache

# 2. Instalar dependências e ZIP (Essencial para não dar erro no Composer)
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev zip unzip libzip-dev libicu-dev \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# 3. Configurar Git
RUN git config --global --add safe.directory /var/www/html

# 4. Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. Extensões PHP
RUN docker-php-ext-configure intl \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip

# 6. --- A CORREÇÃO DO VENDEDOR (APACHE) ---
# Isso habilita o servidor a ler o .htaccess. Sem isso, dá erro 404/MIME no JS.
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf
RUN a2enmod rewrite
# Força o AllowOverride All direto na configuração mestre
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# 7. Copiar arquivos
WORKDIR /var/www/html
COPY . .

# 8. --- CRIAR O .HTACCESS AUTOMATICAMENTE ---
# Garante que o arquivo exista mesmo se o upload falhar
RUN echo "<IfModule mod_rewrite.c>\n\
    <IfModule mod_negotiation.c>\n\
        Options -MultiViews -Indexes\n\
    </IfModule>\n\
    RewriteEngine On\n\
    RewriteRule ^(.*)/$ /\$1 [L,R=301]\n\
    RewriteCond %{REQUEST_FILENAME} !-d\n\
    RewriteCond %{REQUEST_FILENAME} !-f\n\
    RewriteRule ^ index.php [L]\n\
</IfModule>" > /var/www/html/public/.htaccess

# 9. Build e Permissões
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs
RUN npm install && npm run build
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
