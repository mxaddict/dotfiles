import type { Plugin } from '@opencode-ai/plugin';

// Play rickroll + notification when session idle (turn complete).
export const RickPlugin: Plugin = async ({ $ }) => {
    return {
        event: async ({ event }: { event: { type: string } }) => {
            if (event.type === 'session.idle') {
                $`/home/mxaddict/.local/bin/.rick`.quiet().nothrow();
            }
        },
    };
};
