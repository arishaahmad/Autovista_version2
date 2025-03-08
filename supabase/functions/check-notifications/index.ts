import { corsHeaders } from '../_shared/cors.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'

console.log(`Function "check-notifications" up and running!`)

// Helper function to check for recent notifications
async function hasRecentNotification(
  supabaseClient: any,
  userId: string,
  type: string,
  relatedId: string,
  daysThreshold: number = 1
) {
  const thresholdDate = new Date();
  thresholdDate.setDate(thresholdDate.getDate() - daysThreshold);

  const { data: recentNotifications } = await supabaseClient
    .from('notifications')
    .select('*')
    .eq('user_id', userId)
    .eq('type', type)
    .gte('created_at', thresholdDate.toISOString())
    .filter('data->document_id', 'eq', relatedId)
    .filter('data->car_id', 'eq', relatedId);

  return recentNotifications && recentNotifications.length > 0;
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Missing environment variables')
    }

    const supabaseClient = createClient(supabaseUrl, supabaseKey)

    // Get all users
    const { data: users, error: usersError } = await supabaseClient
      .from('users')
      .select('id, name, email')

    if (usersError) throw usersError

    for (const user of users) {
      // Check for document expiry
      const { data: documents, error: documentsError } = await supabaseClient
        .from('documents')
        .select('*')
        .eq('user_id', user.id)

      if (documentsError) throw documentsError

      const now = new Date()
      const thirtyDaysFromNow = new Date(now.getTime() + (30 * 24 * 60 * 60 * 1000))

      for (const doc of documents) {
        // Check if document has an expiry date
        if (doc.expiry_date) {
          const expiryDate = new Date(doc.expiry_date)
          if (expiryDate <= thirtyDaysFromNow) {
            // Check for recent notifications before creating a new one
            const hasRecent = await hasRecentNotification(
              supabaseClient,
              user.id,
              'document_expiry',
              doc.id
            );

            if (!hasRecent) {
              // Create notification for document expiry
              await supabaseClient
                .from('notifications')
                .insert({
                  user_id: user.id,
                  title: 'Document Expiry Reminder',
                  body: `Your ${doc.category} document will expire on ${expiryDate.toLocaleDateString()}`,
                  type: 'document_expiry',
                  data: JSON.stringify({ document_id: doc.id }),
                  is_read: false,
                  created_at: new Date().toISOString(),
                })
            }
          }
        }
      }

      // Check for maintenance reminders
      const { data: cars, error: carsError } = await supabaseClient
        .from('cars')
        .select('*')
        .eq('user_id', user.id)

      if (carsError) throw carsError

      for (const car of cars) {
        // Check last oil change date
        if (car.last_oil_change_date) {
          const lastOilChange = new Date(car.last_oil_change_date)
          const threeMonthsFromLastOilChange = new Date(lastOilChange.getTime() + (90 * 24 * 60 * 60 * 1000))

          if (now >= threeMonthsFromLastOilChange) {
            // Check for recent notifications before creating a new one
            const hasRecent = await hasRecentNotification(
              supabaseClient,
              user.id,
              'maintenance',
              car.id
            );

            if (!hasRecent) {
              // Create notification for oil change reminder
              await supabaseClient
                .from('notifications')
                .insert({
                  user_id: user.id,
                  title: 'Maintenance Reminder',
                  body: `It's time for an oil change for your ${car.brand} ${car.model}`,
                  type: 'maintenance',
                  data: JSON.stringify({ car_id: car.id, maintenance_type: 'oil_change' }),
                  is_read: false,
                  created_at: new Date().toISOString(),
                })
            }
          }
        }

        // Check mileage for general maintenance
        if (car.mileage && car.mileage >= 5000) {
          // Check for recent notifications before creating a new one
          const hasRecent = await hasRecentNotification(
            supabaseClient,
            user.id,
            'maintenance',
            car.id
          );

          if (!hasRecent) {
            // Create notification for general maintenance check
            await supabaseClient
              .from('notifications')
              .insert({
                user_id: user.id,
                title: 'Maintenance Reminder',
                body: `Your ${car.brand} ${car.model} has reached ${car.mileage}km. Consider scheduling a maintenance check.`,
                type: 'maintenance',
                data: JSON.stringify({ car_id: car.id, maintenance_type: 'general' }),
                is_read: false,
                created_at: new Date().toISOString(),
              })
          }
        }
      }
    }

    return new Response(
      JSON.stringify({ message: 'Notifications checked and sent successfully' }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})