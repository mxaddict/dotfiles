import type { Plugin } from '@opencode-ai/plugin';

// Play rickroll + notification when session idle (turn complete).
// Only fires if prompt took >= 30s (threshold enforced inside .rick).
// State file scoped per session to avoid cross-session collisions.
export const RickPlugin: Plugin = async ({ $ }) => {
    const home = process.env.HOME ?? '';
    const user = process.env.USER ?? 'user';
    const rickBin = `${home}/.local/bin/.rick`;
    const statePath = (sid: string) => `/tmp/.rick-start-${user}-${sid}`;

    return {
        'chat.params': async (input: any) => {
            const sid = input?.sessionID ?? 'default';
            $`sh -c ${`date +%s > ${statePath(sid)}`}`.quiet().nothrow();
        },
        event: async ({ event }: { event: any }) => {
            if (event.type === 'session.idle') {
                const sid = event.properties?.sessionID ?? 'default';
                $`sh -c ${`RICK_STATE=${statePath(sid)} ${rickBin}`}`
                    .quiet()
                    .nothrow();
            }
        },
    };
};
