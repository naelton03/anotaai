# AnotaAI Campeonatos

Aplicativo Flutter para gerenciamento de campeonatos esportivos com persistência local em SQLite, interface responsiva para mobile/tablet e pipeline para geração de APK.

## Funcionalidades

- criação de campeonatos com formato, descrição, datas, privacidade e personalização visual básica;
- persistência local real em SQLite para campeonatos, equipes, jogadores, fases, rodadas e partidas;
- cadastro de equipes com status e grupo;
- cadastro de jogadores com busca, filtros e importação em massa via CSV colado no app;
- gestão de fases, rodadas, partidas e atualização de resultados;
- classificação automática e rankings de artilharia/assistências;
- dashboard inicial com resumo do campeonato e próximos jogos;
- interface mobile com shell visual inspirado em aplicativos esportivos e navegação inferior dedicada.

## Rodando localmente

```bash
flutter create --platforms=android .
flutter pub get
flutter run
```

## Build do APK

```bash
flutter create --platforms=android .
flutter build apk --release
```

## CI

O workflow `.github/workflows/android-apk.yml` instala o Flutter, resolve dependências, executa análise e testes, e publica o APK gerado como artifact.
