<h1>Panduan Upgrade Wakapi (untuk Fork Pribadi)</h1>
<p>Dokumen ini adalah panduan langkah demi langkah dan praktik terbaik untuk melakukan upgrade instance Wakapi yang di-hosting sendiri. Alur kerja ini didasarkan pada penggunaan fork pribadi dari repositori asli, koneksi Git via SSH, dan manajemen rahasia menggunakan Docker Secrets.</p>

<h2>Langkah-langkah Upgrade</h2>
<p>Ikuti proses ini secara berurutan untuk memastikan upgrade berjalan lancar dan aman.</p>

<h3>Langkah 1: Backup (Penting!)</h3>
<p>Jangan pernah melewatkan langkah ini. Selalu buat cadangan data database Anda sebelum melakukan perubahan apa pun.</p>
# Masuk ke direktori aplikasi
<pre><code>
cd ~/wakapi
</code></pre>
# Jalankan skrip backup yang sudah ada
<pre><code>
./backup_wakapi.sh
</code></pre>

<h3>Langkah 2: Ambil Pembaruan dari Repositori Asli (Upstream)</h3>
<p>Perintah ini akan mengunduh semua commit dan branch terbaru dari developer Wakapi tanpa mengubah file lokal Anda.</p>
<pre><code>
git fetch upstream
</code></pre>

<h3>Langkah 3: Gabungkan Pembaruan</h3>
<p>Pastikan Anda berada di branch <code>master</code> lokal Anda, lalu gabungkan perubahan yang baru saja diunduh dari <code>upstream/master</code>.</p>
# Pindah ke branch master jika belum
<pre><code>
git checkout master
</code></pre>

# Gabungkan perubahan
<pre><code>
git merge upstream/master
</code></pre>

<h3>Langkah 4: Selesaikan Konflik (Jika Terjadi)</h3>
<p>Ada kemungkinan pembaruan dari upstream mengubah file yang sama dengan yang Anda ubah (misalnya <code>compose.yml</code> atau <code>config.default.yml</code>). Jika ini terjadi, <code>git merge</code> akan gagal dan melaporkan adanya conflict.</p>
<ol>
    <li>Jalankan <code>git status</code> untuk melihat file mana yang konflik.</li>
    <li>Buka file tersebut dengan editor (<code>nano &lt;nama-file&gt;</code>).</li>
    <li>Cari penanda <code>&lt;&lt;&lt;&lt;&lt;&lt;&lt;</code>, <code>=======</code>, <code>&gt;&gt;&gt;&gt;&gt;&gt;&gt;</code>.</li>
    <li>Edit file tersebut secara manual untuk menggabungkan kedua versi menjadi satu versi final yang benar.</li>
    <li>Setelah selesai, tandai konflik sebagai selesai:</li>
</ol>
<pre><code>git add &lt;nama-file-yang-konflik&gt;
git commit
</code></pre>
<p>(Git akan membuka editor untuk pesan commit, Anda bisa langsung menyimpannya).</p>

<h3>Langkah 5: Push Hasil Gabungan ke Fork Anda (origin)</h3>
<p>Setelah proses merge (dan penyelesaian konflik) berhasil, perbarui repositori Anda sendiri di GitHub dengan kode terbaru.</p>
<pre><code>git push origin master
</code></pre>

<h3>Langkah 6: Terapkan Perubahan dengan Docker Compose</h3>
<p>Ini adalah langkah final untuk mem-build ulang image aplikasi dengan kode baru dan memulai ulang kontainer.</p>
<pre><code>docker-compose up -d --build
</code></pre>
<p>Perintah ini akan secara otomatis:</p>
<ul>
    <li>Membangun ulang image <code>wakapi</code> dari Dockerfile dan kode sumber terbaru.</li>
    <li>Membuat ulang kontainer <code>wakapi-app</code> dengan image baru tersebut.</li>
    <li>Menyambungkan kembali semua volume dan secrets yang ada.</li>
</ul>

<h2>Setelah Upgrade</h2>

<h3>Langkah 7: Verifikasi</h3>
<p>Pastikan semuanya berjalan dengan baik.</p>
<ul>
    <li><strong>Cek Log:</strong> Lihat output log untuk memastikan tidak ada pesan error saat startup.</li>
</ul>
<pre><code>docker-compose logs -f
</code></pre>
<ul>
    <li><strong>Cek Aplikasi:</strong> Buka Wakapi di browser Anda, login, dan pastikan semua data lama Anda masih ada dan fungsionalitas berjalan normal.</li>
</ul>

<h3>Langkah 8: Bersihkan Image Lama</h3>
<p>Setelah beberapa kali upgrade, akan ada banyak image Docker lama yang tidak terpakai. Bersihkan untuk menghemat ruang disk.</p>
<pre><code>docker image prune
</code></pre>
<p>Ketik <code>y</code> saat diminta konfirmasi. Perintah ini aman dan hanya akan menghapus image yang tidak lagi digunakan oleh kontainer manapun.</p>
