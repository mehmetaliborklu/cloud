name: Build and Deploy to Render

on:
  push:
    branches:
      - master  # veya 'main' (yaptığınız değişikliklerin yükleneceği branch)

jobs:
  build:
    runs-on: ubuntu-latest  # Linux ortamında çalışacak

    steps:
      # Kodunuzu GitHub reposundan alıyoruz
      - name: Checkout kaynak kodu
        uses: actions/checkout@v3

      # Java kurulumu (Spring Boot için Java 17 önerilir)
      - name: Set up Java 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'  # OpenJDK Temurin dağıtımı

      # Maven wrapper kullanarak uygulamayı build ediyoruz
      - name: Build Spring Boot app
        run: |
          chmod +x ./mvnw  # Eğer Windows'dan kaynaklı izin problemi varsa, bu komutla betiği çalıştırılabilir yapıyoruz
          ./mvnw clean package -DskipTests  # Maven Wrapper ile derleme

  deploy:
    runs-on: ubuntu-latest
    needs: build  # Build aşamasının başarılı olmasını bekliyoruz

    steps:
      # Render'a deploy etmek için gerekli ayarlar
      - name: Deploy to Render
        uses: johnbeynon/render-deploy-action@v0.0.8
        with:
          service-id: ${{ secrets.RENDER_SERVICE_ID }}  # Render servisi ID'si
          api-key: ${{ secrets.RENDER_API_KEY }}      # Render API anahtarı
