diff --git a/resources/assets/js/install/index.js b/resources/assets/js/install/index.js
new file mode 100644
index 0000000000000000000000000000000000000000..76c8bcf0d5c0d79b2ff299a01fefa7eec0987628
--- /dev/null
+++ b/resources/assets/js/install/index.js
@@ -0,0 +1,160 @@
+`use strict`;
+
+import Alpine from 'alpinejs';
+import { Api } from '../api.js';
+
+const api = new Api();
+api.base = '/install';
+api.config.toast = false;
+
+const defaultRequirements = () => ({
+    is_satisfied: false,
+    config: [],
+    ext: [],
+    write_access: [],
+});
+
+window.installer = (version, ip) => ({
+    version,
+    ip,
+    step: 'welcome',
+    requirements: defaultRequirements(),
+    error: null,
+    isProcessing: false,
+    envReady: false,
+    model: {
+        license: '',
+        db: {
+            host: 'localhost',
+            port: '3306',
+            name: '',
+            user: '',
+            password: '',
+            driver: 'pdo_mysql',
+        },
+        account: {
+            first_name: '',
+            last_name: '',
+            email: '',
+            password: '',
+        },
+        migrate: false,
+        hasData: false,
+    },
+    init() {
+        this.hideLoader();
+    },
+    hideLoader() {
+        if (this.$refs?.loading) {
+            this.$refs.loading.style.display = 'none';
+        }
+    },
+    view(step) {
+        if (this.isProcessing) {
+            return;
+        }
+        this.error = null;
+        this.step = step;
+    },
+    async viewRequirement() {
+        if (this.isProcessing) {
+            return;
+        }
+        this.isProcessing = true;
+        this.error = null;
+
+        try {
+            const response = await api.get('/requirements');
+            this.requirements = response.data || defaultRequirements();
+            this.step = 'requirements';
+        } catch (error) {
+            this.error = error?.message || 'Failed to load requirements.';
+        } finally {
+            this.isProcessing = false;
+            this.hideLoader();
+        }
+    },
+    submitLicenseForm() {
+        if (this.isProcessing) {
+            return;
+        }
+        this.error = null;
+        this.step = 'db';
+    },
+    async submitDbForm() {
+        if (this.isProcessing) {
+            return;
+        }
+        this.isProcessing = true;
+        this.error = null;
+
+        try {
+            const response = await api.post('/database', {
+                name: this.model.db.name,
+                user: this.model.db.user,
+                password: this.model.db.password,
+                host: this.model.db.host,
+                port: this.model.db.port,
+                driver: this.model.db.driver,
+            });
+
+            this.model.hasData = Boolean(response.data?.has_data);
+            this.model.migrate = Boolean(response.data?.migrate);
+
+            if (response.data?.user) {
+                this.model.account = {
+                    ...this.model.account,
+                    first_name: response.data.user.first_name || '',
+                    last_name: response.data.user.last_name || '',
+                    email: response.data.user.email || '',
+                };
+            }
+
+            await api.post('/env', { db: this.model.db });
+            this.envReady = true;
+
+            this.step = this.model.hasData ? 'migration' : 'account';
+        } catch (error) {
+            this.error = error?.message || 'Failed to verify database credentials.';
+        } finally {
+            this.isProcessing = false;
+        }
+    },
+    async install() {
+        if (this.isProcessing) {
+            return;
+        }
+        this.isProcessing = true;
+        this.error = null;
+
+        try {
+            if (!this.envReady) {
+                await api.post('/env', { db: this.model.db });
+                this.envReady = true;
+            }
+
+            await api.post('/database/scheme', {
+                migrate: this.model.migrate,
+            });
+
+            await api.post('/presets/import');
+
+            if (!this.model.migrate) {
+                await api.post('/users', this.model.account);
+            }
+
+            await api.post('/activate', {
+                license: this.model.license,
+            });
+
+            this.step = 'success';
+        } catch (error) {
+            this.error = error?.message || 'Installation failed.';
+            this.step = 'failure';
+        } finally {
+            this.isProcessing = false;
+        }
+    },
+});
+
+Alpine.start();
