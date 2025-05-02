import { useEffect } from 'react';
import useAudioAnalyzer from '@/hooks/useAudioAnalyzer';

export default function DebugTools() {
    const { getFrequencyData } = useAudioAnalyzer();

    useEffect(() => {
        const handleKey = (e: KeyboardEvent) => {
            if (e.key === 'd') {
                const result = getFrequencyData();
                if (result) {
                    const { logFreqTexture, head } = result;
                    const data = logFreqTexture.image.data as Uint8Array;
                    console.log(...data.slice(head, head + 22));
                }
            }
        };
    
        window.addEventListener('keydown', handleKey);
        return () => window.removeEventListener('keydown', handleKey);
    }, []);

    return null;
}


