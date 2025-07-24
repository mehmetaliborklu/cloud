name: Build and Deploy to Render

on:
  push:
    branches:
      - master  # veya 'main'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout kaynak kodu
        uses: actions/checkout@v3

      - name: Java kurulumu
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build Spring Boot app
        run: ./mvnw clean package -DskipTests

  deploy:
    runs-on: ubuntu-latest
    needs: build

    steps:
      - name: Deploy to Render
        uses: johnbeynon/render-deploy-action@v0.0.8
        with:
          service-id: ${{ secrets.RENDER_SERVICE_ID }}
          api-key: ${{ secrets.RENDER_API_KEY }}
