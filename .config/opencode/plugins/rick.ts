import type { Plugin } from '@opencode-ai/plugin';

// Play rickroll + notification when session idle (turn complete).
// Only fires if prompt took >= 30s (threshold enforced inside .rick).
// State file scoped per session to avoid cross-session collisions.
export const RickPlugin: Plugin = async ({ $ }) => {
    const statePath = (sid: string) =>
        `/tmp/.rick-start-${process.env.USER}-${sid}`;

    return {
        'chat.params': async (input: any) => {
            const sid = input?.sessionID ?? 'default';
            $`sh -c ${`date +%s > ${statePath(sid)}`}`.quiet().nothrow();
        },
        event: async ({ event }: { event: any }) => {
            if (event.type === 'session.idle') {
                const sid = event.properties?.sessionID ?? 'default';
                $`sh -c ${`RICK_STATE=${statePath(sid)} /home/mxaddict/.local/bin/.rick`}`
                    .quiet()
                    .nothrow();
            }
        },
    };
};
