// web/flutter_bootstrap.js
// Inicia o app e tira o aviso "Carregando o Brincaki..." quando ele abre.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    document.getElementById('carregando')?.remove();
  },
});
