# ==========================================
# ESTÁGIO 1: BUILD (Compilação)
# ==========================================
# Usamos uma imagem com o Maven e Java 21 para compilar o projeto
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /app

# 1. Copiar apenas o pom.xml primeiro
COPY pom.xml .

# 2. Descarregar dependências (Isto cria cache. Se não mudares as dependências,
# o Docker salta este passo nas próximas vezes, poupando minutos preciosos!)
RUN mvn dependency:go-offline

# 3. Copiar o código fonte e compilar
COPY src ./src
RUN mvn clean package -DskipTests

# ==========================================
# ESTÁGIO 2: RUN (Execução)
# ==========================================
# Usamos uma imagem super leve apenas com o ambiente de execução (JRE)
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# 4. Roubar o JAR gerado no Estágio 1 (ignorando o resto do lixo de compilação)
COPY --from=builder /app/target/*.jar app.jar

# 5. Avisar qual é a porta que a aplicação usa
EXPOSE 8080

# 6. O comando final para arrancar o motor
ENTRYPOINT ["java", "-jar", "app.jar"]