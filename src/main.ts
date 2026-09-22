import {vec3} from 'gl-matrix';
import Stats from 'stats-js';
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

import lambertVertSource from './shaders/lambert-vert.glsl?raw';
import lambertFragSource from './shaders/lambert-frag.glsl?raw';

import spiritVertSource from './shaders/custom-vert.glsl?raw';
import spiritFragSource from './shaders/custom-frag.glsl?raw';

import backgroundVertSource from './shaders/bg-vert.glsl?raw';
import backgroundFragSource from './shaders/bg-frag.glsl?raw';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  spiritAnger: 0, // higher is more red, 0 is default
  spiritHyperness: 0, // how fast the animations go
  spiritEmbarassment: 0, // how tall the tongues are


 'Reset Spirit': function() {
    controls.spiritAnger = 0;
    controls.spiritHyperness = 0;
    controls.spiritEmbarassment = 0;
 },


  'Load Scene': loadScene, // A function pointer, essentially
};

let icosphere: Icosphere;
let square: Square;
let prevTesselations: number = 5;
let time = 0.0;


function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'spiritAnger', 0.0, 1.0).listen(); // apparently needs .listen() to update
  gui.add(controls, 'spiritHyperness', 0.0, 5.0).listen();
  gui.add(controls, 'spiritEmbarassment', 0.0, 2.0).listen();
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'Reset Spirit');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);

  // BACKGROUND
  renderer.setClearColor(0.067, 0.051, 0.078, 1);

  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, lambertVertSource),
    new Shader(gl.FRAGMENT_SHADER, lambertFragSource),
  ]);


  const spirit = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, spiritVertSource),
    new Shader(gl.FRAGMENT_SHADER, spiritFragSource),
  ]);

  const background = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, backgroundVertSource),
    new Shader(gl.FRAGMENT_SHADER, backgroundFragSource),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    spirit.setCameraPos(camera.controls.eye);
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }


    renderer.render(camera, background, [
      square,
    ]);

    renderer.render(camera, spirit, [
      icosphere,
      // square,
    ]);
    stats.end();

    time += 0.01;
    spirit.setTime(time);
    background.setTime(time);

    spirit.setSpiritAnger(controls.spiritAnger);
    spirit.setSpiritEmbarassment(controls.spiritEmbarassment);
    spirit.setSpiritHyperness(controls.spiritHyperness);


    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
