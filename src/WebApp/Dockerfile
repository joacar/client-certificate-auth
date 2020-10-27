# Default image
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-buster-slim AS base
# Company image
#FROM mcr.microsoft.com/dotnet/core/sdk:3.1.300-alpine AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Default image doens't produce any warnings adding root certificate to /usr/local/share/ca-certificates/
# and running update-ca-certificates
FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build
# Company image
#FROM mcr.microsoft.com/dotnet/core/sdk:3.1-bionic AS build
# results in:
#  Step 18/19 : RUN update-ca-certificates
#  ---> Running in 83fa21a320d3
#  WARNING: ca-certificates.crt does not contain exactly one certificate or CRL: skipping

WORKDIR /src
COPY ["src/WebApp/WebApp.csproj", "src/WebApp/"]
RUN dotnet restore "src/WebApp/WebApp.csproj"
COPY . .
WORKDIR "/src/src/WebApp"
RUN dotnet build "WebApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "WebApp.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
# cer is copied during publish
ADD cca_root_ca.cer /usr/local/share/ca-certificates/cca_root_ca.crt
RUN update-ca-certificates

ENTRYPOINT ["dotnet", "WebApp.dll"]
