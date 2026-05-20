export function success(body: unknown) {
  return { statusCode: 200, headers: corsHeaders(), body: JSON.stringify(body) };
}

export function created(body: unknown) {
  return { statusCode: 201, headers: corsHeaders(), body: JSON.stringify(body) };
}

export function error(statusCode: number, message: string) {
  return { statusCode, headers: corsHeaders(), body: JSON.stringify({ error: message }) };
}

function corsHeaders() {
  return {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  };
}
