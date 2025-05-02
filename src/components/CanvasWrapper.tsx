import { Canvas } from '@react-three/fiber';
import ShaderCanvas from './ShaderCanvas';
import DebugTools from './DebugTools';

export default function CanvasWrapper() {
  return (
    <><ShaderCanvas /><DebugTools /></>
  );
}
