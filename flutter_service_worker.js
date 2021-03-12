'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "version.json": "20d3aab2e277490ba1620967f9bd9bf4",
"index.html": "202cd29a848f920c07746f54e8e5a244",
"/": "202cd29a848f920c07746f54e8e5a244",
"main.dart.js": "a4d4466f4ef8aea2758d9fb4d24d359c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "79517cce78bc4e8ea7d65e14c91b0f26",
".git/config": "38881ccff4dc4e249623736f3cd97a15",
".git/objects/61/cd2bfb29181021d050528fc525db02e9d66023": "9e0c0f45665c57531638a3181da54b64",
".git/objects/50/cd774b29d4a9a080f9e3d782b7c671e96c3d38": "0df89511688cfabaecdfea391282f71c",
".git/objects/68/9c1389f36ba4e589134b77ae592a84ef6897a1": "d4cf6d1e774b59b9153f884b3802ec3f",
".git/objects/68/68f7bb64ba71b131690286ddc82aa0f542293e": "b6aeab417f5d5ef28ea070a09b61c7e0",
".git/objects/3b/4821cb994dfac89ae107e707c8fef404451e80": "711ebb76c6cb677e69b27b05ad887bb3",
".git/objects/6a/d1de3f9df4eb5df0790e38dbed4c89186c1022": "ee8ded86da628e55c2f05be2f4e6cf3a",
".git/objects/35/63e7347be1ef18a3a447df1cd5d049cc088e14": "410c839ec94204d5a12c81538aae3317",
".git/objects/35/acda2fa1196aad98c2adf4378a7611dd713aa3": "b485406370fdb56248ec4e5fc074fb65",
".git/objects/67/bd84202ad5b2e307d3b6fac1731c2a5d963e0b": "aa161ace139f434c81be219b6f6205e5",
".git/objects/94/8f0a5d26e899539e7821aa5a500932f76ba582": "e9093d046b81c96e5fd46a48a0b68b11",
".git/objects/5f/72e9127ffaae2a500cd9d950067f46c21b277c": "9334d3373cb9fc449377becf4cba5477",
".git/objects/33/0c523a1d037e2e1446cd5d69a4f513eb3bca7a": "c15b7e2dbb4950a1d4e4e54abf25b20c",
".git/objects/9c/2e612405c8c28c4abee9ae8319001659e8e7e7": "c649847ef06513d2ba285fa22dbe7a56",
".git/objects/02/4cc77accadba74ea6c13ba1258aab9770e42b0": "1e31605fbef283b13de2fb508279b483",
".git/objects/a4/12dd9386f28a78753897dbd04f7fc625a905db": "c3a04564a65950c798588f53585395f1",
".git/objects/a4/46a8ddb6743047b25f1f2877412af37e43a131": "c76e909fb67aa396ebda163188e66f7b",
".git/objects/a3/09313d5fb20765dff1d8f41dbd72c558097611": "ce77a88cc2b115d907f98afb245fa5f6",
".git/objects/b2/7565f857cb894f1cefb370de74fb6ac1814b29": "0b4868561b526a22dcad261127df056c",
".git/objects/bb/23a489d5e5bd28daeea99243d70cb38e959e82": "83f7c8bc2ed8b3a10bfe34569ed932e1",
".git/objects/d7/587f5341ec2d74a42379a82970c5b1724090d1": "84c88ce136335d7a4e29e66bc5791e62",
".git/objects/b4/8a104e510e8cf751acebac148ba8ccb411cd41": "c2bed30d4910668a295c00416e973a02",
".git/objects/d1/dbd98e34b53fa064a07448a410998a36e51379": "84e2e07286c258847da465931d17b13b",
".git/objects/bc/6f1d57f8843a31354077c4759b2d9960cc0757": "e818611f6640b8d4fcdfe405318b85b6",
".git/objects/eb/1832bc36e9f1bf6553e8553d2bf1f2e25fa51d": "725793661b8a93f66e7f9f87a4115e62",
".git/objects/c7/90e045bfef5a65717c0a794781478f7e3b138b": "c867fe9ce2b283e2314e1e55c5539d54",
".git/objects/fc/4ef71de36daf69ff0882284b5bc9416d745bd6": "40d0539d2163802bf35300e022cfcca6",
".git/objects/fc/963dfe2292c4e241afb5950e063414d544c093": "8cd8693ced3c797431323a7707d38029",
".git/objects/f2/5787c93ad00665f0f797a43ab397f0628a273e": "59e425d1456034072d902c75d18ec75f",
".git/objects/f5/eaf7eb1511bd9532cebfae70e47524663de109": "50b1229f40423533da8629dc65d38889",
".git/objects/cf/e2d9f8fd1f1602ac2944104150deb151250322": "138cd42be5f7f5389f94211921b22a97",
".git/objects/ca/7bce8f1454a4bf135837daffd9f26bb93fe676": "40e0e5a1a0e1960f039a738dcf61d792",
".git/objects/e4/ae46c6286b2d6c6676b0c3192fc92876778498": "c1fb9fd9132eb732a1d95b1d7a283648",
".git/objects/fe/62ead26d30d5ec37a25d6074445b7712b8a6f7": "b21341041c8ff6d748d0d60595d9f6fc",
".git/objects/c8/df92b853992397794e13e57140bbab28367e15": "4e587a7e4ba7acfc9ac1796c5c862e78",
".git/objects/ed/c6c6ef4d9a4c5edafc9e74c86983fb5000f04e": "5cca105e93941731b5f3f39d8f67bcaf",
".git/objects/ed/188124ed3e3b950e291d90823b3fbc93243ae8": "77312b294daa110fbb96a49c989ad418",
".git/objects/20/5bb5db271c6d8de8399864c7bb9b917f638893": "c993b22f115d7f3ae6d5b7b212806539",
".git/objects/4b/0ac8d5dc159ddfd026798f8215a6c2b7ba8a82": "0ccc36c32aeb3b5a4ac2119420bbca07",
".git/objects/74/10f865e643ee6dface663ce3528df572876cef": "75f1c100df6872bfc6971272383d61d5",
".git/objects/1a/5fe55c9e05e4425cb09a4f0a83518fd6b3a810": "1205d995cb2e47ab157440b94989d15d",
".git/objects/28/7e0a1f569f4c442fc0354239b3bc2fb9eb69cb": "8ee08cb7906770a41c034b1be1af8a31",
".git/objects/17/1aab1323cc71ab49a7d2541d5bebbb54e6eb7b": "15015ca97e4a181bf8d31c3d4512ba64",
".git/objects/8a/7690b87b68ca099f051d85f2fb613282fe4ed7": "a8f9f4550bae0680df7cd66eb9117de6",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/7e/ce3282a4f7824b249d9e568819d98bd2fa3da6": "8c71b613b9912dfd1fdf473a52e99214",
".git/objects/44/a477711745bc6bafbeea50b915807f096b510d": "022c2a870d0da85c5f8d264b44b2f87e",
".git/objects/2a/bf03542c17e6f7a7806a226c3be732b51c5a40": "4593012a42df8795cd0ae089a5b7aaaf",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/6b/369a6c1ecaac361def4e86234925ee8468cae6": "826b9189687037da6d5f86884eb2d70c",
".git/objects/6e/cb68683477ecc5aed38ec3fc8910d9bb66276c": "8081799c6f0d89b405c8cca2b18cd6da",
".git/objects/5c/ab0f911f7e40e0eca1beb326b692371771bfc7": "f13ac1651d3dea7713a6860abf1338b4",
".git/objects/5c/68ffe87495ac85e931514fedda4f2c79013187": "b2c226b45a575337aaf7558edf7bf8f1",
".git/objects/5d/4aeafc38116d4b0f50976fc2e19cfa73ca9004": "78e02af7e9f6434720248421dfebf22c",
".git/objects/91/a2a44fd31e05a9e439b630cff6b253ec9cb033": "e4aa50b272aa1613f11fa04cd11cb98f",
".git/objects/62/91d7ab89ca101fa62f562e23f42af59fb57d7c": "aeabefd924a20c87090e764ea5063402",
".git/objects/96/cdea4bccfb946cc123e8e2ee78a0a5002979c5": "d293c8d91dc352195647c706aaa2deb7",
".git/objects/08/7819947ab9d32dc5497bcb5e1a23c4f2783928": "3a5aa562ee824232792c68096c1560b0",
".git/objects/08/af3378fa687af860192933d260cdfc905b287c": "6b1c3c64f2788a3bf45c4db04bf83a7a",
".git/objects/6c/62094d5af6140bc576f73e5583185f221a6a12": "9602dfc01198795afb3f9fb69258286a",
".git/objects/6c/ce217ddc2efe3411dc9fa34e294e48e4cdf4f5": "8a6cc32e7f23f25e611213b06bb38448",
".git/objects/39/2a93b71607b4d9f9cc379c5b9a8e000726d7ac": "5d89eb41756b5e771dd914fdd560f161",
".git/objects/52/6be56c0354e6a353ba6d31ddfa137e45b33830": "61c984a861c15358085f29ef04eda254",
".git/objects/55/01662834aff80a57820d751fd6cdd51476a4d1": "799c17028c96cc95fd782ceb5650e406",
".git/objects/0f/fe00b92b2e2d21c1f33024760f685cbb7ffdb8": "6655e717f185770489b36816ed0d52de",
".git/objects/64/50399d1c2ab36f22254794ca7dd200354f61ba": "c114af8aa65348a05d7ee526f0b18381",
".git/objects/d4/9783198f7accfc8dda9917ebb488d6875fe9a9": "428e6268756e38d51814329c0bdad50e",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/a8/3a17d54b6dc2156c855c6580301cefc9c8d017": "6525101be8d70b808a809af9c83fa4ad",
".git/objects/de/132609f12a3b791afeef7a5fd973e79e06ba9c": "7da5e8ddfae9195cfab10a099eb60f1f",
".git/objects/a1/0bbf9576154ff39bb9f2c51fc348bcca5bcc3b": "1d15e69aefdea67dc1f3b00731271e54",
".git/objects/ef/6f088794b27444669a11085f630bbd0bfa9b3b": "b14092451b04300892cafc1968118933",
".git/objects/c3/3f28409d8329beed81fe13171f059c04a4f53d": "1908a27a2496d77907efd9051280a2c9",
".git/objects/c4/df55120f4a4715ee5ca45e87f0f3ccae27612b": "a6c2132024adb0af29e201955ef6f3f8",
".git/objects/cd/e583242130f42647c83c160764ddde7448fba9": "3c47cb7f7c934a5bdf374b5889a312e2",
".git/objects/fa/4ac30f27aef0b6ace0789e89346f2f4f8d5992": "b249fc00989f5332e742bd8c4abcd790",
".git/objects/2d/196f86d81e618dca6ca3680b3c0dd755a336b4": "2f3b56a436fd4d2490bbf18c8d596e2f",
".git/objects/41/dca81857c7ec8a3b0251a2cd8ff0309313c2ad": "148681b804a1000c5a2d4669d49f44ee",
".git/objects/70/15564ad166a3e9d88c82f17829f0cc01ebe29a": "b0b4eb8e40c5eaa3b07c9dcc175a4ab8",
".git/objects/1c/8f5e910bfb1a4a2871eeedc6eae01ca25e7ce1": "7d52f9ae3b3fac811829018aea2c668f",
".git/objects/13/5a3f566ef0f67f055309dc4ab65aa26ac69967": "b9e902e0488ad9c20b4e1c6698a09098",
".git/objects/7a/f27ce67e125df391e78fc1968ce33c6d173257": "753236ea26dc1e5acb2eba4db70643e6",
".git/objects/14/c84ace93cf085a309ec3c96537b124b0c2a19b": "bed47f562dce92c86bf438aa7ed321db",
".git/HEAD": "4cf2d64e44205fe628ddd534e1151b58",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "6e0ab762513d1cdb4a3e30d832083f3c",
".git/logs/refs/heads/master": "6e0ab762513d1cdb4a3e30d832083f3c",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-commit.sample": "e4db8c12ee125a8a085907b757359ef0",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "ecbb0cb5ffb7d773cd5b2407b210cc3b",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "3c5989301dd4b949dfa1f43738a22819",
".git/hooks/update.sample": "517f14b9239689dff8bda3022ebd9004",
".git/refs/heads/master": "29a17f5756e7eb2cc4c9d7fd6cdeebf6",
".git/index": "5524e83303322892af6b54e9f0c06027",
".git/COMMIT_EDITMSG": "45c9eb7fa6e6a781268f8a3b8d62d8b9",
"assets/AssetManifest.json": "8ac8777905fe842c6d277f30d6706aa5",
"assets/NOTICES": "c3aee35475bfaec78ff5e8d66de9a904",
"assets/FontManifest.json": "f890bb4fef0b87ed497472896d76d917",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "b14fcf3ee94e3ace300b192e9e7c8c5d",
"assets/packages/flutter_icons/fonts/Octicons.ttf": "73b8cff012825060b308d2162f31dbb2",
"assets/packages/flutter_icons/fonts/Feather.ttf": "6beba7e6834963f7f171d3bdd075c915",
"assets/packages/flutter_icons/fonts/Entypo.ttf": "744ce60078c17d86006dd0edabcd59a7",
"assets/packages/flutter_icons/fonts/FontAwesome5_Brands.ttf": "c39278f7abfc798a241551194f55e29f",
"assets/packages/flutter_icons/fonts/MaterialCommunityIcons.ttf": "3c851d60ad5ef3f2fe43ebd263490d78",
"assets/packages/flutter_icons/fonts/AntDesign.ttf": "3a2ba31570920eeb9b1d217cabe58315",
"assets/packages/flutter_icons/fonts/Foundation.ttf": "e20945d7c929279ef7a6f1db184a4470",
"assets/packages/flutter_icons/fonts/weathericons.ttf": "4618f0de2a818e7ad3fe880e0b74d04a",
"assets/packages/flutter_icons/fonts/Ionicons.ttf": "b2e0fc821c6886fb3940f85a3320003e",
"assets/packages/flutter_icons/fonts/FontAwesome5_Solid.ttf": "b70cea0339374107969eb53e5b1f603f",
"assets/packages/flutter_icons/fonts/FontAwesome5_Regular.ttf": "f6c6f6c8cb7784254ad00056f6fbd74e",
"assets/packages/flutter_icons/fonts/FontAwesome.ttf": "b06871f281fee6b241d60582ae9369b9",
"assets/packages/flutter_icons/fonts/Zocial.ttf": "5cdf883b18a5651a29a4d1ef276d2457",
"assets/packages/flutter_icons/fonts/EvilIcons.ttf": "140c53a7643ea949007aa9a282153849",
"assets/packages/flutter_icons/fonts/SimpleLineIcons.ttf": "d2285965fe34b05465047401b8595dd0",
"assets/packages/flutter_icons/fonts/MaterialIcons.ttf": "a37b0c01c0baf1888ca812cc0508f6e2",
"assets/fonts/MaterialIcons-Regular.otf": "1288c9e28052e028aba623321f7826ac",
"assets/assets/snippets/linked_list.lox": "e841a98b165e636f416edc3be3784a28",
"assets/assets/snippets/inheritance.lox": "a0da1a50e6ca1fe2f563fb7142dd196d",
"assets/assets/snippets/closure.lox": "03550d9a0dde828036fd2b19b2156227",
"assets/assets/snippets/precedence.lox": "8f0fbcfb2aa5ab3da547c55db1f2821d",
"assets/assets/snippets/containers.lox": "ea621bac12f2576110ba4e3126e42413",
"assets/assets/snippets/fibonacci.lox": "3332135d9421b181ba6c16f5e4a3655c",
"assets/assets/snippets/benchmark.lox": "79fb068be624b75c2454cf0acdb31a40",
"assets/assets/fonts/sourceCode/SourceCodePro-LightItalic.ttf": "ac76390ae8518be5c0a0bd1f3b088b4b",
"assets/assets/fonts/sourceCode/SourceCodePro-SemiBold.ttf": "420d3580f5b6e63ba1eabb8555b5f6cf",
"assets/assets/fonts/sourceCode/SourceCodePro-Medium.ttf": "f621c504d70317ff13774e27d643ba21",
"assets/assets/fonts/sourceCode/SourceCodePro-SemiBoldItalic.ttf": "6406c55397f0f20723d6b2c2f6515348",
"assets/assets/fonts/sourceCode/SourceCodePro-MediumItalic.ttf": "0b54cce890a75c2227718eaf473068ba",
"assets/assets/fonts/sourceCode/SourceCodePro-Light.ttf": "a8d6f8bb989fc3c860ad2eeac21f9daa",
"assets/assets/fonts/sourceCode/SourceCodePro-BlackItalic.ttf": "fb68d27992feaf97dab1e5640a6f5812",
"assets/assets/fonts/sourceCode/SourceCodePro-BoldItalic.ttf": "c8066b7adaa839e5f0590da2d34723be",
"assets/assets/fonts/sourceCode/SourceCodePro-Black.ttf": "efa63de0d44af1e7de9e01a4467dd423",
"assets/assets/fonts/sourceCode/SourceCodePro-ExtraLight.ttf": "cba7ccef6b4071f76245cc0c5e659aa9",
"assets/assets/fonts/sourceCode/SourceCodePro-Regular.ttf": "b484b32fcec981a533e3b9694953103b",
"assets/assets/fonts/sourceCode/SourceCodePro-ExtraLightItalic.ttf": "b98dab96118c3500d0e8c3f887fcfb26",
"assets/assets/fonts/sourceCode/SourceCodePro-Italic.ttf": "c088801620ae4d69924da74e879170a9",
"assets/assets/fonts/sourceCode/SourceCodePro-Bold.ttf": "03c11f6b0c0f707075d6483a78824c60"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "/",
"main.dart.js",
"index.html",
"assets/NOTICES",
"assets/AssetManifest.json",
"assets/FontManifest.json"];
// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value + '?revision=' + RESOURCES[value], {'cache': 'reload'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});

// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache.
        return response || fetch(event.request).then((response) => {
          cache.put(event.request, response.clone());
          return response;
        });
      })
    })
  );
});

self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});

// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}

// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
