const normalize = v => { const d=Math.hypot(...v); return v.map(x=>x/d); };
// Development-only renderer for the approved recessed plunger. The application
// uses the generated sprite sheet; it does not depend on WebGL or JavaScript.
const dot = (a,b) => a.reduce((s,x,i)=>s+x*b[i],0);
const view = normalize([0,0.62,0.79]);
function lathe(profile, material) {
  const segments=120, rings=profile.map(([r,y],i)=>{
    const before=profile[Math.max(0,i-1)],after=profile[Math.min(profile.length-1,i+1)];
    const dr=after[0]-before[0],dy=after[1]-before[1];
    return Array.from({length:segments},(_,j)=>{
      const a=j/segments*Math.PI*2,c=Math.cos(a),s=Math.sin(a);
      return {p:[r*c,y,r*s],n:normalize([dy*c,-dr,dy*s])};
    });
  });
  const triangles=[];
  for(let i=0;i<rings.length-1;i++) for(let j=0;j<segments;j++) {
    const k=(j+1)%segments;
    for(const vertices of [[rings[i][j],rings[i][k],rings[i+1][k]],[rings[i][j],rings[i+1][k],rings[i+1][j]]]) {
      const normal=normalize([0,1,2].map(axis=>vertices.reduce((s,v)=>s+v.n[axis],0)));
      if(dot(normal,view)>-0.05) triangles.push({vertices,normal,material});
    }
  }
  return triangles;
}
const ring=lathe([[0.94,0],[1.04,0],[1.085,0.025],[1.105,0.075],[1.106,0.12],[1.095,0.17],[1.07,0.21],[1.025,0.235],[0.98,0.239],[0.945,0.218],[0.924,0.18],[0.913,0.125],[0.912,0.03]],'chrome');
const cap=lathe([[0,0.015],[0.83,0.015],[0.864,0.026],[0.883,0.058],[0.883,0.315],[0.882,0.358],[0.873,0.395],[0.85,0.419],[0.816,0.433],[0.74,0.449],[0.6,0.46],[0.42,0.471],[0.2,0.477],[0,0.479]],'plastic');
const geometry=[...ring,...cap];
function createGpu(canvas) {
  const gl=canvas.getContext('webgl',{alpha:true,antialias:true,preserveDrawingBuffer:true});
  if(!gl)return null;
  function shader(type,source) {
    const s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);
    if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));
    return s;
  }
  const program=gl.createProgram();
  gl.attachShader(program,shader(gl.VERTEX_SHADER,`
    attribute vec3 aPosition; attribute vec3 aNormal; attribute float aMaterial;
    uniform float uDepression; uniform float uAspect;
    varying vec3 normal; varying float material;
    void main(){
      vec3 v=normalize(vec3(0.,.62,.79));
      vec3 p=aPosition;
      // The moving body ends inside the housing, above its bottom plane.
      if(aMaterial>.5)p.y=max(.012,p.y-uDepression);
      float sy=-p.y*v.z+p.z*v.y;
      gl_Position=vec4(p.x/1.24,1.-2.*(.55+sy*uAspect/2.48),-dot(p,v)/4.,1.);
      normal=aNormal;material=aMaterial;
    }
  `));
  gl.attachShader(program,shader(gl.FRAGMENT_SHADER,`
    precision highp float;
    varying vec3 normal; varying float material;
    uniform vec3 uColor;uniform float uShine;
    void main(){
      vec3 n=normalize(normal),v=normalize(vec3(0.,.62,.79));
      float facing=max(0.,dot(n,v));vec3 r=2.*facing*n-v;
      vec3 color;
      if(material<.5){
        float sky=max(0.,r.y),floorLight=max(0.,-r.y);
        float box=pow(max(0.,dot(r,normalize(vec3(-.38,.80,.46)))),12.);
        float side=pow(max(0.,dot(r,normalize(vec3(.82,.28,.42)))),22.);
        float light=clamp(.63+.18*sky+.66*box+.58*side-.40*floorLight,0.,1.);
        color=vec3(.96,.98,1.)*light;
      }else{
        vec3 key=normalize(vec3(-3.,5.,4.)),fill=normalize(vec3(4.,2.,3.));
        float diffuse=.73+.20*max(0.,dot(n,key))+.10*max(0.,dot(n,fill));
        float spec=.18*pow(max(0.,dot(r,normalize(vec3(-.2,.60,-.78)))),28.);
        spec+=.28*pow(max(0.,dot(n,normalize(key+v))),48.);
        spec+=.04*pow(1.-facing,3.);
        color=uColor*diffuse+vec3(spec*uShine);
      }
      gl_FragColor=vec4(clamp(color,0.,1.),1.);
    }
  `));
  gl.linkProgram(program);
  if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(program));
  gl.useProgram(program);
  const data=new Float32Array(geometry.flatMap(t=>t.vertices.flatMap(v=>[...v.p,...v.n,t.material==='plastic'?1:0])));
  gl.bindBuffer(gl.ARRAY_BUFFER,gl.createBuffer());gl.bufferData(gl.ARRAY_BUFFER,data,gl.STATIC_DRAW);
  for(const [name,count,offset] of [['aPosition',3,0],['aNormal',3,12],['aMaterial',1,24]]) {
    const at=gl.getAttribLocation(program,name);gl.enableVertexAttribArray(at);gl.vertexAttribPointer(at,count,gl.FLOAT,false,28,offset);
  }
  gl.enable(gl.DEPTH_TEST);gl.depthFunc(gl.LEQUAL);
  const uniform=name=>gl.getUniformLocation(program,name);
  return {gl,program,count:data.length/7,depression:uniform('uDepression'),aspect:uniform('uAspect'),color:uniform('uColor'),shine:uniform('uShine')};
}

window.renderMoveButton = (canvas, player, depression) => {
  const g = canvas.moveButtonGpu ??= createGpu(canvas);
  if (!g) throw Error('WebGL is required to generate the plunger artwork.');
  const gl = g.gl;
  gl.viewport(0, 0, canvas.width, canvas.height);
  gl.clearColor(0, 0, 0, 0);
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  gl.useProgram(g.program);
  gl.uniform1f(g.depression, depression * 0.18);
  gl.uniform1f(g.aspect, canvas.width / canvas.height);
  gl.uniform1f(g.shine, 0.8);
  gl.uniform3fv(g.color, (player === 0 ? [239, 186, 99] : [138, 201, 236]).map(x => x / 255));
  gl.drawArrays(gl.TRIANGLES, 0, g.count);
};
