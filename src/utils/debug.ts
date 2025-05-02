import * as THREE from 'three';

function saveTextureToFile(texture: THREE.DataTexture) {
    const data = texture.image.data as Uint8Array;
    const lines = [];
    for (let y = 0; y < texture.image.height; y++) {
      const row = [];
      for (let x = 0; x < texture.image.width; x++) {
        row.push(data[y * texture.image.width + x]);
      }
      lines.push(row.join(','));
    }
    const blob = new Blob([lines.join('\n')], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'fft_texture_dump.txt';
    a.click();
  }

export { saveTextureToFile };