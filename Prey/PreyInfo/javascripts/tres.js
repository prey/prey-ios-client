// import { EffectComposer, GlitchPass, RenderPass } from "./postprocessing";
//
// var GlitchPass = new GlitchPass() from "postprocessing";
//
if (!Detector.webgl) {
  Detector.addGetWebGLMessage();
}

var container, raycaster;

var stap = false;

var mesh, mesh_hdd, mesh_ram, mesh_mb, mesh_cpu, mesh_lan;

var camera, controls, scene, renderer, effect, uniforms;
var lighting, ambient, keyLight, fillLight, backLight;

var windowHalfX = window.innerWidth / 2;
var windowHalfY = window.innerHeight / 2;

var mouse = new THREE.Vector2(), INTERSECTED;

var radius = 100;

//////////////////////////////////////////////////
// var objs  = ['laptop-lp.obj', 'mb.obj', 'hdd.obj', 'cpu.obj', 'ram.obj', 'lan.obj'];
// var meshs = [mesh,             mesh_mb,  mesh_hdd,  mesh_cpu,  mesh_ram,  mesh_lan];

var objs = ['awesome-phone.obj'];
var meshs = [mesh];

setTimeout(function(){
  animate();
}, 1000)

function init() {

    container = document.createElement('div');
    // var parentElement = document.getElementById("mobile")
    // document.body.appendChild(container);
    $("#device-viewer").append($(container));
    // console.log();

    /* Camera */

    camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.01, 1000);
    camera.position.z = 411;
    camera.position.y = 0;
    camera.position.x = 200;
    camera.focalLength = 3;
    // camera.target.position.copy( mesh );


    /* Scene */

    scene = new THREE.Scene();
    lighting = false;

    ambient = new THREE.AmbientLight(0xffffff, 1.0);
    scene.add(ambient);

    var light = new THREE.DirectionalLight(0xffffff);
    light.position.set(1,1,1);
    scene.add(light);

    /* Model */

    var objLoader = new THREE.OBJLoader();
    // objLoader.setMaterials(materials);
    objLoader.setPath('./../assets/');


    objs.forEach(function(file, index) {
        objLoader.load(file, function (object) {
            object.traverse( function ( child ) {

                if ( child instanceof THREE.Mesh ) {
                  var geometry = child.geometry;
                  var material = child.material;
                  // meshs[index] = new THREE.Mesh(geometry, material);
                  // scene.add(meshs[index]);

                  meshs[index] = new THREE.Mesh(geometry, material);

                  meshs[index].traverse(function (child) {
                    if (child instanceof THREE.Mesh) {
                      // child.material.wireframe = true;
                      // child.material.color = new THREE.Color(0xffffff);
                      geometry = new THREE.Geometry().fromBufferGeometry(child.geometry);
                      // debugger
                    }
                  });

                  scene.add(meshs[index]);


                  // var particleCount = geometry.vertices.length,
                  //     particles = new THREE.Geometry(),
                  //     pMaterial = new THREE.PointsMaterial({
                  //         color: 0xFFFFFF,
                  //         size: 1
                  //     });
                  // for (var p = 0; p < particleCount; p ++) {
                  //     particle = geometry.vertices[p];
                  //     particles.vertices.push(particle);
                  // }
                  // particleSystem = new THREE.Points(particles, pMaterial);
                  // particleSystem.position.set(0, 0, 0)
                  // // particleSystem.scale.set(100,100,100)
                  // scene.add(particleSystem);
                  meshs[index].traverse(function (child) {
                      if (child instanceof THREE.Mesh) {
                          child.material.wireframe = true;
                          child.material.color = new THREE.Color(0x007DEA);
                      }
                  });

                  // var useWireFrame = true;
                  // if (useWireFrame) {
                  //     meshs[index].traverse(function (child) {
                  //         if (child instanceof THREE.Mesh) {
                  //             child.material.wireframe = true;
                  //             child.material.color = new THREE.Color(0xffffff);
                  //         }
                  //     });
                  //
                  // }
                  console.log("INDEX:", index)
                  // if (index == 0)

                }

            });

        });

    })

    // animate();


    // for (i = 0; i < objs.length; i++) {

    // }


    raycaster = new THREE.Raycaster();

    document.addEventListener('mousemove', onDocumentMouseMove, false);

    function onDocumentMouseMove( event ) {
      event.preventDefault();
      mouse.x = ( event.clientX / window.innerWidth ) * 2 - 1;
      mouse.y = - ( event.clientY / window.innerHeight ) * 2 + 1;
    }

    /* Renderer */

    renderer = new THREE.WebGLRenderer({ alpha: true });
    renderer.setPixelRatio(window.devicePixelRatio);
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setClearColor(0x000000, 0);

    container.appendChild(renderer.domElement);

    // effect = new THREE.AnaglyphEffect( renderer );
    // effect.setSize(window.innerWidth, window.innerHeight);

    /* Controls */

    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.25;
    controls.enableZoom = true;
    controls.enablePan = false;

    /* Events */

    window.addEventListener('resize', onWindowResize, false);
    window.addEventListener('keydown', onKeyboardEvent, false);

}

function onWindowResize() {

    windowHalfX = window.innerWidth / 2;
    windowHalfY = window.innerHeight / 2;

    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize(window.innerWidth, window.innerHeight);

    // effect.setSize(window.innerWidth, window.innerHeight);

}

function onKeyboardEvent(e) {

    if (e.code === 'KeyL') {

        lighting = !lighting;

        if (lighting) {

            ambient.intensity = 0.25;
            scene.add(keyLight);
            scene.add(fillLight);
            scene.add(backLight);

        } else {

            ambient.intensity = 1.0;
            scene.remove(keyLight);
            scene.remove(fillLight);
            scene.remove(backLight);

        }

    }
    if (e.code === 'KeyK') {
        camera.position.z = 500;
        camera.position.y = 200;
        meshs[3].position.y = 100;
        meshs[3].position.z = 200;
        stap = true;

    }
    if (e.code === 'KeyJ') {
        meshs[3].position.y = 0;
        meshs[3].position.z = 0;
        stap = false;

    }

}

function animate() {

    requestAnimationFrame(animate);

    if (stap) {
      // mesh.rotation.y = 1;
      controls.autoRotate = false;
    } else {

      // meshs[0].rotation.y -= 0.005;
      // meshs[1].position.y -= 0.5;
      // controls.autoRotate = true;
    }
    controls.update();

    render();

}

function render() {

  // find intersections
  raycaster.setFromCamera( mouse, camera );
  // var intersects = raycaster.intersectObjects( scene.children );
  // if ( intersects.length > 0 ) {
  //   if ( INTERSECTED != intersects[ 0 ].object ) {
  //     if ( INTERSECTED ) INTERSECTED.material.emissive.setHex( INTERSECTED.currentHex );
  //     INTERSECTED = intersects[ 0 ].object;
  //     INTERSECTED.currentHex = INTERSECTED.material.emissive.getHex();
  //     // INTERSECTED.material.emissive.setHex( 0xff0000 );
  //     // stap = true;
  //   }
  // } else {
  //   if ( INTERSECTED ) INTERSECTED.material.emissive.setHex( INTERSECTED.currentHex );
  //   INTERSECTED = null;
  //   // stap = false;
  // }

    renderer.render(scene, camera);

}


// const composer = new EffectComposer(renderer);
// composer.addPass(new RenderPass(new Scene(), new PerspectiveCamera()));
//
// const pass = new GlitchPass();
// pass.renderToScreen = true;
// composer.addPass(pass);
//
// const clock = new Clock();

$(function(){
  init();

  // requestAnimationFrame(render);
  // composer.render(clock.getDelta()); in render()

});




/// ShaderMaterial
//
// THREE.VolumetericLightShader = {
//   uniforms: {
//     tDiffuse: {value:null},
//     lightPosition: {value: new THREE.Vector2(0.5, 0.5)},
//     exposure: {value: 1},
//     decay: {value: 1},
//     density: {value: 5},
//     weight: {value: 0.50},
//     samples: {value: 30}
//   },
//
//   vertexShader: [
//     "varying vec2 vUv;",
//     "void main() {",
//       "vUv = uv;",
//       "gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);",
//     "}"
//   ].join("\n"),
//
//   fragmentShader: [
//     "varying vec2 vUv;",
//     "uniform sampler2D tDiffuse;",
//     "uniform vec2 lightPosition;",
//     "uniform float exposure;",
//     "uniform float decay;",
//     "uniform float density;",
//     "uniform float weight;",
//     "uniform int samples;",
//     "const int MAX_SAMPLES = 100;",
//     "void main()",
//     "{",
//       "vec2 texCoord = vUv;",
//       "vec2 deltaTextCoord = texCoord - lightPosition;",
//       "deltaTextCoord *= 1.0 / float(samples) * density;",
//       "vec4 color = texture2D(tDiffuse, texCoord);",
//       "float illuminationDecay = 1.0;",
//       "for(int i=0; i < MAX_SAMPLES; i++)",
//       "{",
//         "if(i == samples) {",
//           "break;",
//         "}",
//         "texCoord += deltaTextCoord;",
//         "vec4 sample = texture2D(tDiffuse, texCoord);",
//         "sample *= illuminationDecay * weight;",
//         "color += sample;",
//         "illuminationDecay *= decay;",
//       "}",
//       "gl_FragColor = color * exposure;",
//     "}"
//   ].join("\n")
// };
// THREE.AdditiveBlendingShader = {
//   uniforms: {
//     tDiffuse: { value:null },
//     tAdd: { value:null }
//   },
//
//   vertexShader: [
//     "varying vec2 vUv;",
//     "void main() {",
//       "vUv = uv;",
//       "gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);",
//     "}"
//   ].join("\n"),
//
//   fragmentShader: [
//     "uniform sampler2D tDiffuse;",
//     "uniform sampler2D tAdd;",
//     "varying vec2 vUv;",
//     "void main() {",
//       "vec4 color = texture2D(tDiffuse, vUv);",
//       "vec4 add = texture2D(tAdd, vUv);",
//       "gl_FragColor = color + add;",
//     "}"
//   ].join("\n")
// };
// THREE.PassThroughShader = {
//   uniforms: {
//     tDiffuse: { value: null }
//   },
//
//   vertexShader: [
//     "varying vec2 vUv;",
//     "void main() {",
//       "vUv = uv;",
//       "gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);",
//     "}"
//   ].join("\n"),
//
//   fragmentShader: [
//     "uniform sampler2D tDiffuse;",
//     "varying vec2 vUv;",
//     "void main() {",
//       "gl_FragColor = texture2D(tDiffuse, vec2(vUv.x, vUv.y));",
//     "}"
//   ].join("\n")
// };
//
// const getImageTexture = (image, density = 1) => {
//   const canvas = document.createElement('canvas');
//   const ctx = canvas.getContext('2d');
//   const { width, height } = image;
//
//   canvas.setAttribute('width', width * density);
//   canvas.setAttribute('height', height * density);
//   canvas.style.width = `${width}px`;
//   canvas.style.height = `${height}px`;
//
//   ctx.drawImage(image, 0, 0, width * density, height * density);
//
//   return canvas;
// };
//
// const width = 1280;
// const height = 720;
// const lightColor = 0x007DEA;
// const DEFAULT_LAYER = 0;
// const OCCLUSION_LAYER = 1;
// const renderScale = .25;
// const gui = new dat.GUI();
// const clock = new THREE.Clock();
//
// let composer,
//     filmPass,
//     badTVPass,
//     bloomPass,
//     occlusionComposer,
//     itemMesh,
//     occMesh,
//     occRenderTarget,
//     lightSource,
//     vlShaderUniforms;
//
// const scene = new THREE.Scene();
// const camera = new THREE.PerspectiveCamera(75, width / height, 0.1, 1000);
// const renderer = new THREE.WebGLRenderer({
//   antialias: false
// });
// renderer.setSize(width, height);
// // renderer.setPixelRatio(window.devicePixelRatio);
// renderer.setClearColor(0x14222C, 0.1);
// document.body.appendChild(renderer.domElement);
//
// function setupScene() {
//   lightSource = new THREE.Object3D();
//   lightSource.position.x = 0;
//   lightSource.position.y = -15;
//   lightSource.position.z = -15;
//
//   const itemGeo = new THREE.PlaneGeometry(10, 6);
//   const itemMaterial = new THREE.MeshBasicMaterial({transparent: true, opacity: 0.7});
//
//   const img = new Image();
//   img.src = '../images/android-phone.png';
//   img.crossOrigin = 'Anonymous';
//
//   img.onload = function() {
//     const itemTexture = new THREE.Texture(
//       getImageTexture(img),
//       null,
//       THREE.ClampToEdgeWrapping,
//       THREE.ClampToEdgeWrapping,
//       null,
//       THREE.LinearFilter
//    );
//
//     itemTexture.needsUpdate = true;
//     itemMaterial.map = itemTexture;
//
//     itemMesh = new THREE.Mesh(itemGeo, itemMaterial);
//     scene.add(itemMesh);
//
//     const occItemMaterial = new THREE.MeshBasicMaterial({color: lightColor});
//     occItemMaterial.map = itemTexture;
//     occMesh = new THREE.Mesh(itemGeo, occItemMaterial);
//     occMesh.layers.set(OCCLUSION_LAYER);
//     scene.add(occMesh);
//   }
//
//   camera.position.z = 6;
//   camera.position.y = -0.5;
// }
//
// function setupPostprocessing() {
//   occRenderTarget = new THREE.WebGLRenderTarget(width * renderScale, height * renderScale);
//
//   // Blur passes
//   const hBlur = new THREE.ShaderPass(THREE.HorizontalBlurShader);
//   const vBlur = new THREE.ShaderPass(THREE.VerticalBlurShader);
//   const bluriness = 7;
//   hBlur.uniforms.h.value = bluriness / width;
//   vBlur.uniforms.v.value = bluriness / height;
//
//   // Bad TV Pass
//   badTVPass = new THREE.ShaderPass(THREE.BadTVShader);
//   badTVPass.uniforms.distortion.value = 1.5;
//   badTVPass.uniforms.distortion2.value = 1.5;
//   badTVPass.uniforms.speed.value = 0.2;
//   badTVPass.uniforms.rollSpeed.value = 0;
//
//   // Volumetric Light Pass
//   const vlPass = new THREE.ShaderPass(THREE.VolumetericLightShader);
//   vlShaderUniforms = vlPass.uniforms;
//   vlPass.needsSwap = false;
//
//   // Occlusion Composer
//   occlusionComposer = new THREE.EffectComposer(renderer, occRenderTarget);
//   occlusionComposer.addPass(new THREE.RenderPass(scene, camera));
//   occlusionComposer.addPass(hBlur);
//   occlusionComposer.addPass(vBlur);
//   occlusionComposer.addPass(hBlur);
//   occlusionComposer.addPass(vBlur);
//   occlusionComposer.addPass(hBlur);
//   occlusionComposer.addPass(badTVPass);
//   occlusionComposer.addPass(vlPass);
//
//   // Bloom pass
//   bloomPass = new THREE.UnrealBloomPass(width / height, 0.5, .8, .3);
//
//   // Film pass
//   filmPass = new THREE.ShaderPass(THREE.FilmShader);
//   filmPass.uniforms.sCount.value = 500;
//   filmPass.uniforms.grayscale.value = false;
//   filmPass.uniforms.sIntensity.value = 1.2;
//   filmPass.uniforms.nIntensity.value = 0.2;
//
//   // Blend occRenderTarget into main render target
//   const blendPass = new THREE.ShaderPass(THREE.AdditiveBlendingShader);
//   blendPass.uniforms.tAdd.value = occRenderTarget.texture;
//   blendPass.renderToScreen = true;
//
//   // Main Composer
//   composer = new THREE.EffectComposer(renderer);
//   composer.addPass(new THREE.RenderPass(scene, camera));
//   // composer.addPass(bloomPass);
//   composer.addPass(badTVPass);
//   composer.addPass(filmPass);
//   composer.addPass(blendPass);
// }
//
// function onFrame() {
//   requestAnimationFrame(onFrame);
//   update();
//   render();
// }
//
// function update() {
//   const timeDelta = clock.getDelta();
//   const elapsed = clock.getElapsedTime();
//
//   // filmPass.uniforms.time.value += timeDelta;
//   badTVPass.uniforms.time.value += 0.01;
//
//   if (itemMesh) {
//     itemMesh.rotation.y = Math.sin(elapsed / 2) / 10;
//     itemMesh.rotation.z = Math.cos(elapsed / 2) / 50;
//     occMesh.rotation.copy(itemMesh.rotation);
//   }
// }
//
// function render() {
//   camera.layers.set(OCCLUSION_LAYER);
//   // renderer.setClearColor(0x000000);
//   // renderer.setSize(window.innerWidth, window.innerHeight);
//   occlusionComposer.render();
//
//   camera.layers.set(DEFAULT_LAYER);
//   composer.render();
// }
//
// function setupGUI() {
//   let folder,
//       min,
//       max,
//       step,
//       updateShaderLight = function() {
//         const p = lightSource.position.clone(),
//             vector = p.project(camera),
//             x = (vector.x + 1) / 2,
//             y = (vector.y + 1) / 2;
//         vlShaderUniforms.lightPosition.value.set(x, y);
//       };
//
//   updateShaderLight();
//
//   // Bloom Controls
//   folder = gui.addFolder('Bloom');
//   folder.add(bloomPass, 'radius')
//     .min(0)
//     .max(10)
//     .name('Radius');
//   folder.add(bloomPass, 'threshold')
//     .min(0)
//     .max(1)
//     .name('Threshold');
//   folder.add(bloomPass, 'strength')
//     .min(0)
//     .max(10)
//     .name('Strength');
//   folder.open();
//
//    // Bad TV Controls
//   folder = gui.addFolder('TV');
//   folder.add(badTVPass.uniforms.distortion, 'value')
//     .min(0)
//     .max(10)
//     .name('Distortion 1');
//   folder.add(badTVPass.uniforms.distortion2, 'value')
//     .min(0)
//     .max(10)
//     .name('Distortion 2');
//   folder.add(badTVPass.uniforms.speed, 'value')
//     .min(0)
//     .max(1)
//     .name('Speed');
//   folder.add(badTVPass.uniforms.rollSpeed, 'value')
//     .min(0)
//     .max(10)
//     .name('Roll Speed');
//   folder.open();
//
//   // Light Controls
//   folder = gui.addFolder('Light Position');
//   folder.add(lightSource.position, 'x')
//     .min(-50)
//     .max(50)
//     .onChange(updateShaderLight);
//   folder.add(lightSource.position, 'y')
//     .min(-50)
//     .max(50)
//     .onChange(updateShaderLight);
//   folder.add(lightSource.position, 'z')
//     .min(-50)
//     .max(50)
//     .onChange(updateShaderLight);
//   folder.open();
//
//   // Volumetric Light Controls
//   folder = gui.addFolder('Volumeteric Light Shader');
//   folder.add(vlShaderUniforms.exposure, 'value')
//     .min(0)
//     .max(1)
//     .name('Exposure');
//   folder.add(vlShaderUniforms.decay, 'value')
//     .min(0)
//     .max(1)
//     .name('Decay');
//   folder.add(vlShaderUniforms.density, 'value')
//     .min(0)
//     .max(10)
//     .name('Density');
//   folder.add(vlShaderUniforms.weight, 'value')
//     .min(0)
//     .max(1)
//     .name('Weight');
//   folder.add(vlShaderUniforms.samples, 'value')
//     .min(1)
//     .max(100)
//     .name('Samples');
//
//   folder.open();
// }
//
// function addRenderTargetImage() {
//   const material = new THREE.ShaderMaterial(THREE.PassThroughShader);
//   material.uniforms.tDiffuse.value = occRenderTarget.texture;
//
//   const mesh = new THREE.Mesh(new THREE.PlaneBufferGeometry(2, 2), material);
//   composer.passes[1].scene.add(mesh);
//   mesh.visible = false;
//
//   const folder = gui.addFolder('Light Pass Render Image');
//   folder.add(mesh, 'visible');
//   folder.open();
// }
//
// setupScene();
// setupPostprocessing();
// onFrame();
// setupGUI();
// addRenderTargetImage();
