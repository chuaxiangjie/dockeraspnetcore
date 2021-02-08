#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.


FROM mcr.microsoft.com/dotnet/aspnet:5.0-buster-slim AS base
WORKDIR /app

# Create a group and user so we are not running our container and application as root and thus user 0 which is a security issue.
RUN addgroup --system --gid 1000 customgroup \
    && adduser --system --uid 1000 --ingroup customgroup --shell /bin/sh customuser
  
# Serve on port 8080, we cannot serve on port 80 with a custom user that is not root.
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
  
# Tell docker that all future commands should run as the appuser user, must use the user number
USER 1000

#FROM mcr.microsoft.com/dotnet/sdk:5.0-buster-slim AS build

FROM mcr.microsoft.com/dotnet/sdk:5.0-focal AS build

WORKDIR /src
COPY ["dockeraspnetcore.csproj", ""]
RUN dotnet restore "./dockeraspnetcore.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "dockeraspnetcore.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "dockeraspnetcore.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "dockeraspnetcore.dll"]