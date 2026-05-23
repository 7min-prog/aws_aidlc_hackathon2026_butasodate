export declare function success(body: unknown): {
    statusCode: number;
    headers: {
        'Content-Type': string;
        'Access-Control-Allow-Origin': string;
        'Access-Control-Allow-Headers': string;
    };
    body: string;
};
export declare function created(body: unknown): {
    statusCode: number;
    headers: {
        'Content-Type': string;
        'Access-Control-Allow-Origin': string;
        'Access-Control-Allow-Headers': string;
    };
    body: string;
};
export declare function error(statusCode: number, message: string): {
    statusCode: number;
    headers: {
        'Content-Type': string;
        'Access-Control-Allow-Origin': string;
        'Access-Control-Allow-Headers': string;
    };
    body: string;
};
//# sourceMappingURL=response.d.ts.map