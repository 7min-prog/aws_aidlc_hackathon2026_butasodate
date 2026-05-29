export declare function success(body: any, statusCode?: number): {
    statusCode: number;
    headers: {
        'Content-Type': string;
        'Access-Control-Allow-Origin': string;
    };
    body: string;
};
export declare function error(message: string, statusCode?: number): {
    statusCode: number;
    headers: {
        'Content-Type': string;
        'Access-Control-Allow-Origin': string;
    };
    body: string;
};
//# sourceMappingURL=response.d.ts.map