import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

const AdminLive = () => {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <header className="container py-10">
        <h1 className="text-3xl font-bold">Admin Live Operations</h1>
        <p className="text-muted-foreground mt-2">Monitor active rides, driver availability, and key metrics in real time.</p>
      </header>

      <section className="container grid gap-6 md:grid-cols-3 pb-10">
        <Card>
          <CardHeader>
            <CardTitle>Active Rides</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-semibold">12</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Online Drivers</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-semibold">38</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Avg Wait (min)</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-semibold">4.6</p>
          </CardContent>
        </Card>
      </section>

      <section className="container pb-16">
        <Card>
          <CardHeader>
            <CardTitle>Live Rides</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="rounded-lg border overflow-hidden">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Ride</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Rider</TableHead>
                    <TableHead>Driver</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>ETA</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {[1,2,3,4,5].map((id) => (
                    <TableRow key={id}>
                      <TableCell>RID-{id.toString().padStart(4, '0')}</TableCell>
                      <TableCell>{id % 2 === 0 ? 'Drop' : 'Cluster'}</TableCell>
                      <TableCell>Jane Doe</TableCell>
                      <TableCell>John Driver</TableCell>
                      <TableCell>
                        <span className="inline-flex items-center gap-2 text-sm">
                          <span className="h-2 w-2 rounded-full bg-primary" /> En‑route
                        </span>
                      </TableCell>
                      <TableCell>{(6 - id) + 2} min</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      </section>
    </main>
  );
};

export default AdminLive;
