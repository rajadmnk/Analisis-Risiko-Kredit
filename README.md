# Analisis-Risiko-Kredit

## Project Objective
Proyek ini menganalisis 32.409 akun pinjaman untuk mengidentifikasi karakteristik peminjam dan pinjaman yang berkaitan dengan risiko gagal bayar yang lebih tinggi. Analisis dilakukan dengan SQL (BigQuery) untuk menjawab enam business question, mulai dari profil risiko portofolio, faktor peminjam dan pinjaman, konsistensi grade, titik patah rasio pinjaman terhadap pendapatan (loan-to-income), sampai segmen berisiko tinggi dan tier risiko untuk pemantauan. Hasilnya dirangkum dalam presentasi, dokumen storytelling, dan dashboard Power BI satu halaman.

Temuan utama: default rate portofolio 21,87%. Tier High Risk hanya berisi 16,9% akun, tetapi menyumbang 51,9% dari seluruh default. Risiko melonjak tajam mulai grade D dan pada loan-to-income sekitar 30%, terutama pada peminjam berstatus sewa.

## Tools
SQL (BigQuery), Power BI (DAX), Microsoft Excel & PowerPoint

## Key Learnings
- Menentukan cutoff secara data-driven: saya memakai band halus, margin error 95%, dan syarat sampel minimum, bukan menebak angka bulat.
- Menentukan pada batas bucket. Pembulatan floating point membuat nilai tepat 0,30 masuk band yang salah, dan temuan ini mengubah cara saya mengecek hasil query.
- Membaca dan memilah data kecil. Segmen di bawah 100 akun disembunyikan agar default rate tidak menyesatkan.
- Grade dan suku bunga saling berkorelasi, sehingga tidak boleh dihitung ganda dalam skor risiko.
Hasil ini asosiasi pada data observasi, bukan sebab-akibat, dan cutoff perlu divalidasi pada data lain.
- Mengubah analisis menjadi cerita dan tindakan: tier risiko yang bisa dipakai untuk pemantauan dan keputusan kredit.

## Dataset
[Link](https://www.kaggle.com/datasets/laotse/credit-risk-dataset)

## Analysis
[Link](https://docs.google.com/presentation/d/e/2PACX-1vR-Q6zJ5RztL-Z9Tk0Mb_RsHxhnCUo0O6OsZTECvssh7OvIGZIwmMuFaH7bRv5AQQ/pub?start=false&loop=false&delayms=3000)

## Dashboard
[tampilan dashboard][<img width="691" height="388" alt="Dasboard" src="https://github.com/user-attachments/assets/4127846f-92ac-41a8-acc0-b5a12b63acc3" />

