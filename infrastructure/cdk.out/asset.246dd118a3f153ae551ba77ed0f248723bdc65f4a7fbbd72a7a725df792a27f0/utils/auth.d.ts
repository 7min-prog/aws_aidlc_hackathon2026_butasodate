export declare function generateToken(username: string): string;
export declare function verifyToken(token: string): {
    sub: string;
} | null;
export declare function validateBasicAuth(user: string, password: string): boolean;
export declare const authMiddleware: import("hono").MiddlewareHandler<any, any, {}>;
