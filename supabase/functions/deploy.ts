const projectRef = 'qmxoticuvkdmeyteyvaa';
const functionName = 'check-notifications';
const functionPath = './supabase/functions/check-notifications/index.ts';

async function deployFunction() {
  const response = await fetch(
    `https://${projectRef}.supabase.co/functions/v1/deploy`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: functionName,
        file: await Deno.readTextFile(functionPath),
        verify_jwt: false,
      }),
    }
  );

  if (!response.ok) {
    throw new Error(`Failed to deploy: ${await response.text()}`);
  }

  console.log('Function deployed successfully!');
  console.log(await response.json());
}

deployFunction().catch(console.error);