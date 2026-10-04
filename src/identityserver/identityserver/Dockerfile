FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY identityserver.csproj ./
RUN dotnet restore
COPY . .
RUN dotnet publish identityserver.csproj --configuration Release --output /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runner
WORKDIR /app
EXPOSE 5001

RUN mkdir -p /app/keys /app/diagnostics \
    && chown -R $APP_UID:$APP_UID /app/keys /app/diagnostics

COPY --from=build --chown=$APP_UID:$APP_UID /app/publish ./
USER $APP_UID
ENTRYPOINT ["dotnet", "identityserver.dll"]
