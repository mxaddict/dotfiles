import type { Plugin } from '@opencode-ai/plugin';

// Play rickroll + notification when session idle (turn complete).
// Only fires if prompt took >= 30s (threshold enforced inside .rick).
export const RickPlugin: Plugin = async ({ $ }) => {
    return {
        'chat.params': async () => {
            $`sh -c 'date +%s > /tmp/.rick-start-$USER'`.quiet().nothrow();
        },
        event: async ({ event }: { event: { type: string } }) => {
            if (event.type === 'session.idle') {
                $`/home/mxaddict/.local/bin/.rick`.quiet().nothrow();
            }
        },
    };
};
