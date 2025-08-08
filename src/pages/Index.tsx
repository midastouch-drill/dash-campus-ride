import { Link } from "react-router-dom";
import { Button } from "@/components/ui/button";

const Index = () => {
  return (
    <main className="min-h-screen bg-background text-foreground">
      <header className="container py-16">
        <section className="mx-auto max-w-3xl text-center space-y-6">
          <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
            Dash Campus Ride‑Hailing — Drop & Cluster Rides
          </h1>
          <p className="text-muted-foreground text-lg">
            Affordable, fast, and student‑first rides. Real‑time tracking, secure wallet payments,
            and a beautiful, accessible experience.
          </p>
          <div className="flex items-center justify-center gap-3 pt-2">
            <Button asChild>
              <Link to="#get-started" aria-label="Get started with Dash">Get started</Link>
            </Button>
            <Button variant="secondary" asChild>
              <Link to="/admin/live" aria-label="Open admin live operations">Admin live</Link>
            </Button>
          </div>
        </section>
      </header>

      <section id="get-started" className="container pb-24">
        <article className="grid md:grid-cols-3 gap-6">
          <div className="rounded-lg border bg-card p-6">
            <h2 className="text-xl font-semibold">Drop rides</h2>
            <p className="text-sm text-muted-foreground mt-2">Point‑to‑point in minutes with transparent fares.</p>
          </div>
          <div className="rounded-lg border bg-card p-6">
            <h2 className="text-xl font-semibold">Cluster rides</h2>
            <p className="text-sm text-muted-foreground mt-2">Share routes, reduce costs, and keep wait times low.</p>
          </div>
          <div className="rounded-lg border bg-card p-6">
            <h2 className="text-xl font-semibold">Secure payments</h2>
            <p className="text-sm text-muted-foreground mt-2">Wallet‑first with instant top‑ups and receipts.</p>
          </div>
        </article>
      </section>
    </main>
  );
};

export default Index;
