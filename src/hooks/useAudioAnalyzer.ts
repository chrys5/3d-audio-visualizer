import { log } from 'console';
import { useEffect, useRef } from 'react';
import * as THREE from 'three';

export default function useAudioAnalyzer() {
    const HISTORY_MILLISECONDS = 5000; // 5 seconds

    const FFT_SIZE = 16384; // Size of the FFT (must be a power of 2)
    const FREQ_BUFFER_FRAMES = 5; // Number of samples to keep in history
    const FREQ_BUFFER_SIZE = FFT_SIZE * FREQ_BUFFER_FRAMES; // Total size of the frequency buffer

    const FREQ_BINS = [12, 33, 72, 105, 155, 229, 338, 498, 734, 1082, 1596, 2353, 3468, 7538, 16384];
    const LOG_FFT_SIZE = FREQ_BINS.length;
    const LOG_FREQ_BUFFER_SIZE = LOG_FFT_SIZE * FREQ_BUFFER_FRAMES; // Total size of the log frequency buffer

    const analyserRef = useRef<AnalyserNode | null>(null);
    const dataArrayRef = useRef<Uint8Array | null>(null);

    const freqTextureRef = useRef<THREE.DataTexture>(null);
    const logFreqTextureRef = useRef<THREE.DataTexture>(null);
    const headRef = useRef<number>(0);

    useEffect(() => {
        let audioContext: AudioContext | null = null;
        let source: MediaStreamAudioSourceNode | null = null;

        async function setupAudio() {
            try {
                audioContext = new AudioContext();
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                source = audioContext.createMediaStreamSource(stream);

                const analyser = audioContext.createAnalyser();
                analyser.fftSize = FFT_SIZE * 2;
                const dataArray = new Uint8Array(FFT_SIZE);
                const freqTextureInit = new Uint8Array(FREQ_BUFFER_SIZE);
                freqTextureInit.fill(0);

                source.connect(analyser);

                analyserRef.current = analyser;
                dataArrayRef.current = dataArray;
                freqTextureRef.current = new THREE.DataTexture(
                    freqTextureInit,
                    FFT_SIZE,
                    FREQ_BUFFER_FRAMES,
                    THREE.RedFormat,
                );
                freqTextureRef.current.minFilter = THREE.NearestFilter;
                freqTextureRef.current.magFilter = THREE.NearestFilter;
                freqTextureRef.current.needsUpdate = true;
                
                const logFreqTextureInit = new Uint8Array(LOG_FREQ_BUFFER_SIZE);
                logFreqTextureRef.current = new THREE.DataTexture(
                    logFreqTextureInit,
                    LOG_FFT_SIZE,
                    FREQ_BUFFER_FRAMES,
                    THREE.RedFormat,
                );
                logFreqTextureRef.current.minFilter = THREE.NearestFilter;
                logFreqTextureRef.current.magFilter = THREE.NearestFilter;
                logFreqTextureRef.current.needsUpdate = true;
            } catch (error) {
                console.error('Error accessing audio input:', error);
                return;
            }
        }

        setupAudio();

        return () => {
            if (audioContext) audioContext.close();
        };
    }, []);

    const getFrequencyData = () => {
        if (!analyserRef.current || !dataArrayRef.current || !freqTextureRef.current || !logFreqTextureRef.current) return null;

        analyserRef.current.getByteFrequencyData(dataArrayRef.current);

        const textureData = freqTextureRef.current.image.data as Uint8Array;
        const freqTextureHead = headRef.current * FFT_SIZE;
        for (let i = 0; i < FFT_SIZE; i++) {
            textureData[freqTextureHead + i] = dataArrayRef.current[i];
        };
        freqTextureRef.current.needsUpdate = true;
        
        const logTextureData = logFreqTextureRef.current.image.data as Uint8Array;
        const logFreqTextureHead = headRef.current * LOG_FFT_SIZE;
        for (let i = 0; i < LOG_FFT_SIZE; i++) {
            const start = i == 0 ? 0 : FREQ_BINS[i - 1];
            const end = FREQ_BINS[i];
            let sum: number = 0;
            let maxVal: number = 0;
            for (let j = start; j < end; j++) {
                let value = dataArrayRef.current[j];
                sum += value;
                if (value > maxVal) {
                    maxVal = value;
                }
            }
            const avg = sum / (end - start);
            const weight = 0.4; // 0: only avg, 1: only max
            const weightedAvg = Math.floor(maxVal * weight + avg * (1 - weight));
            logTextureData[logFreqTextureHead + i] = weightedAvg;
        };
        logFreqTextureRef.current.needsUpdate = true;
        
        const currentHead = headRef.current;
        headRef.current = (headRef.current + 1) % FREQ_BUFFER_FRAMES;

        return {
            freqTexture: freqTextureRef.current,
            logFreqTexture: logFreqTextureRef.current,
            head: currentHead
        }
    }

    const getBufferDimensions = () => {
        return { FFT_SIZE, FREQ_BUFFER_FRAMES };
    }

    const getLogBufferDimensions = () => {
        return { LOG_FFT_SIZE, FREQ_BUFFER_FRAMES };
    }

    return { getFrequencyData, getBufferDimensions, getLogBufferDimensions };
}