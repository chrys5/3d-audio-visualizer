'use client';

import { Suspense, useRef } from 'react';
import { Canvas, useFrame, useThree } from '@react-three/fiber';
import * as THREE from 'three';

import vertexShader from '@/shaders/vertex.glsl';
import fragmentShader from '@/shaders/fragment.glsl';
import useDevicePixelRatio from '@/hooks/useDevicePixelRatio';
import useAudioAnalyzer from '@/hooks/useAudioAnalyzer';

const Test = () => {
    const { viewport } = useThree();
    const dpr = useDevicePixelRatio();
    const { getFrequencyData, getLogBufferDimensions } = useAudioAnalyzer();
    const { LOG_FFT_SIZE, FREQ_BUFFER_FRAMES } = getLogBufferDimensions();
    
    const uniforms = useRef({
        iTime: { value: 0 },
        iResolution: {
            value: new THREE.Vector2(window.innerWidth * dpr, window.innerHeight * dpr),
        },
        iAudioTexture: { value: new THREE.DataTexture() },
        iAudioHead: { value: 0 },
        iAudioDimensions: { value: new THREE.Vector2(LOG_FFT_SIZE, FREQ_BUFFER_FRAMES) },
    }).current;

    useFrame((_, delta) => {
        uniforms.iTime.value += delta;
        uniforms.iResolution.value.set(window.innerWidth * dpr, window.innerHeight * dpr);

        const result = getFrequencyData(); // updates history and returns { current, history, head }
        if (result) {
            uniforms.iAudioTexture.value = result.logFreqTexture;
            uniforms.iAudioHead.value = result.head;
        }
    });

    return (
    <mesh scale={[viewport.width, viewport.height, 1]}>
        <planeGeometry args={[1, 1]} />
        <shaderMaterial
        fragmentShader={fragmentShader}
        vertexShader={vertexShader}
        uniforms={uniforms}
        />
    </mesh>
    );
};

export default function TestPage() {
    const dpr = useDevicePixelRatio();
    return (
        <Canvas
            orthographic
            // dpr={1}
            camera={{ position: [0, 0, 6] }}
            style={{
            position: 'fixed',
            top: 0,
            left: 0,
            width: '100vw',
            height: '100vh',
            }}
        >
            <Suspense fallback={null}>
                <Test />
            </Suspense>
        </Canvas>
    );
}
